%MACRO m_trtice() / DES = 'Create ICE parameters in ADEX';
/*******************************************************************************
 * Bayer AG
 * Macro rely on: pure SAS
 *******************************************************************************
 * Purpose          : Create ICE parameters in ADEX
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * Parameters       :
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Preconditions    :
 *     Macrovar. needed:
 *     Datasets  needed:
 *     Ext.Prg/Mac used:
 * Postconditions   :
 *     Macrovar created:
 *     Output   created:
 *     Datasets created:
 * Comments         :
 *******************************************************************************
 * Author(s)        : gmrpb (Fiona Yan) / date: 18AUG2023
 * Reference prog   :
 *******************************************************************************
 * Change History   :
 ******************************************************************************/
/* Changed by       : eokcw (Vijesh Shrivastava) / date: 06SEP2023
 * Reason           : Changed ICEREAS to propcase
 ******************************************************************************/
/* Changed by       : gmrpb (Fiona Yan) / date: 19SEP2023
 * Reason           : Change ICEREAS collected part to sentence case
 ******************************************************************************/

/*******************************************************************************
 * Examples         :
   %m_trtice();
 ******************************************************************************/

** Get subject latest date in study from ADSL.RFPENDT and ADSL.LVDT, whichever is later;
** If at least one of them is missing, generate a user warning and use today date before DBL;
** Once DBL, there should not be such warning;
** This date will be used to determine if subject enter relevant week window;
** If subject did not enter the week window, no ICE record will be created for the target week;
** There will be another check to remove ADEX ICE after permanent discontinuation of treatment in the end of this macro;
data adsl(keep=usubjid day_end trtsdt);
    set ads.adsl(where=(randfl="Y" and not missing(trtsdt)));
    if nmiss(rfpendt,lvdt)>0 then do;
        day_end=today()-trtsdt+1; *ongoing subject;
        put "WARN" "ING: Subject=" USUBJID "is still in the study. Should not be the case once DBL.";
    END;
    else day_end=max(rfpendt,lvdt)-trtsdt+1;
RUN;

** ICE of temp treatment interruption (SAP section 6.5.1) - only for week 1,4,8,12;
data ec_80a ec_5_7a;
   set sp.ec;
   where eccat="STUDY INTERVENTION, DIARY" and ecdose>0 and ecoccur="Y"; *based on the eDiary;

   ** if actual date= planned date or if actual date=planned+1 and time up to 2am ;
   ** THEN dosing date=planned date, otherwise dosing date = actual date;
   if index(ECSTDTC,'T')>0 then do;
       if not (input(scan(ECSTDTC,2,'T'),time5.)>input('02:00',time5.)) then do;
           ECSTDTC= put(input(scan(ECSTDTC,1,'T'),yymmdd10.)-1,yymmdd10.);
           ecstdy=ecstdy-1;
       END;

   END;

   if 1<=ecstdy<=84 then output ec_80a; *to check 80% condition;
   if ecdose>0 then dose=1;
   if 2<=ecstdy<=8 or 15<=ecstdy<=28 or 43<=ecstdy<=56 or 71<=ecstdy<=84 then output ec_5_7a; *to check 5/7 days condition;
RUN;

proc sql;
    create table ec_80b_wk4 as
    select studyid, usubjid, sum(ecdose)/56 as comp_wk4
    from ec_80a
    where 1<=ecstdy<=28
    group by studyid, usubjid;

    create table ec_80b_wk8 as
    select studyid, usubjid, sum(ecdose)/112 as comp_wk8
    from ec_80a
    where 1<=ecstdy<=56
    group by studyid, usubjid;

    create table ec_80b_wk12 as
    select studyid, usubjid, sum(ecdose)/168 as comp_wk12
    from ec_80a
    where 1<=ecstdy<=84
    group by studyid, usubjid;
QUIT;

proc sort data=ec_5_7a;
    by studyid usubjid;
RUN;

proc transpose data=ec_5_7a out=ec_5_7b(drop=_:) prefix=day;
    by studyid usubjid;
    id ecstdy;
    var dose;
RUN;

** in case some subject do not have any dose since day 2 but received dose;
proc sort data=sp.ec out=ec_sub(keep=studyid usubjid) nodupkey;
    where eccat="STUDY INTERVENTION, DIARY" and ECMOOD="PERFORMED";
    by studyid usubjid;
RUN;

data ec_5_7b;
    merge ec_5_7b ec_sub;
    by studyid usubjid;

    if sum(of day2-day8, 0)>=5 then comp2_wk1=1;
    else comp2_wk1=0;
    comp2_wk4=0;
    comp2_wk8=0;
    comp2_wk12=0;

    array w4_day (14) day15-day28;
    array w8_day (14) day43-day56;
    array w12_day (14) day71-day84;

    do i=1 to 8;
        if sum(0,w4_day[i],w4_day[i+1],w4_day[i+2],w4_day[i+3],w4_day[i+4],w4_day[i+5],w4_day[i+6])>=5 then comp2_wk4+1;
        if sum(0,w8_day[i],w8_day[i+1],w8_day[i+2],w8_day[i+3],w8_day[i+4],w8_day[i+5],w8_day[i+6])>=5 then comp2_wk8+1;
        if sum(0,w12_day[i],w12_day[i+1],w12_day[i+2],w12_day[i+3],w12_day[i+4],w12_day[i+5],w12_day[i+6])>=5 then comp2_wk12+1;
    END;
RUN;

data ec;
    merge ec_80b_wk4 ec_80b_wk8 ec_80b_wk12 ec_5_7b(in=a keep=studyid usubjid comp2_wk:);
    by studyid usubjid;
RUN;

data ec2;  *may contain dummy, will be remove later using day_end;
    set ec;
    %createCustomVars(adsDomain=adex, vars = APHASE PARAMCD AVALC PARAMTYP);
    length reason $200;  *manual-assigned reason: may be replaced by ECADJ later if non-missing ECADJ in relevant week window;
    aphase="Week 1-12";
    paramtyp="DERIVED";

    ** week1: Treatment taken on <5/7 days;
    paramcd="TRTINW1";
    if comp2_wk1=1 then avalc="N";
    else do;
        avalc="Y";
        reason="< 5/7 Days";
    END;
    output;

    ** Week 4: Treatment taken <80% during weeks 1-4 OR treatment taken on <5/7 days during any 7-day during week 3/4;
    paramcd="TRTINW4";
    reason="";
    if comp2_wk4=8 and comp_wk4>=0.8 then avalc="N";
    else do;
        avalc="Y";
        if not (comp2_wk4=8) and not (comp_wk4>=0.8) then reason="< 80% Compliance and < 5/7 Days";
        else if not (comp2_wk4=8) then reason="< 5/7 Days";
        else reason="< 80% Compliance";
    END;
    output;

    ** Week 8: Treatment taken <80% during weeks 1-8 OR treatment taken on <5/7 days during any 7-day during week 7/8;
    paramcd="TRTINW8";
    reason="";
    if comp2_wk8=8 and comp_wk8>=0.8 then avalc="N";
    else do;
        avalc="Y";
        if not (comp2_wk8=8) and not (comp_wk8>=0.8) then reason="< 80% Compliance and < 5/7 Days";
        else if not (comp2_wk8=8) then reason="< 5/7 Days";
        else reason="< 80% Compliance";
    END;
    output;

    ** Week 12: Treatment taken <80% during weeks 1-12 OR treatment taken on <5/7 days during any 7-day during week 11/12;
    paramcd="TRTINW12";
    reason="";
    if comp2_wk12=8 and comp_wk12>=0.8 then avalc="N";
    else do;
        avalc="Y";
        if not (comp2_wk12=8) and not (comp_wk12>=0.8) then reason="< 80% Compliance and < 5/7 Days";
        else if not (comp2_wk12=8) then reason="< 5/7 Days";
        else reason="< 80% Compliance";
    END;
    output;
RUN;

** remove dummy;
proc sort data=ec2;
    by usubjid paramcd;
RUN;

data ec3;
    merge ec2(in=a) adsl;
    by usubjid;
    if a;
    if (paramcd="TRTINW1" and day_end>=2) or
       (paramcd="TRTINW4" and day_end>=15) or
       (paramcd="TRTINW8" and day_end>=43) or
       (paramcd="TRTINW12" and day_end>=71);
RUN;

** replace ECADJ with manual-assigned reason if ECADJ exist;
data ecadj;
    set sp.ec(keep=usubjid ecadj ecstdy ecendy);
    where not missing(ecadj) and ecadj^="**";
    %createCustomVars(adsDomain=adex, vars = paramcd);

    if not (ecstdy>8 or .<ecendy<2) and nmiss(ecstdy,ecendy)<2 then do;
        paramcd="TRTINW1";
        output;
    END;

    if not (ecstdy>28 or .<ecendy<15) and nmiss(ecstdy,ecendy)<2 then do;
        paramcd="TRTINW4";
        output;
    END;

    if not (ecstdy>56 or .<ecendy<43) and nmiss(ecstdy,ecendy)<2 then do;
        paramcd="TRTINW8";
        output;
    END;

    if not (ecstdy>84 or .<ecendy<71) and nmiss(ecstdy,ecendy)<2 then do;
        paramcd="TRTINW12";
        output;
    END;
RUN;

proc sort data=ecadj nodupkey;
    by usubjid paramcd ecadj;
RUN;

data ecadj;
    set ecadj;
    ** per shell update, want sentence case;
    ecadj=substr(ecadj,1,1)||lowcase(substr(ecadj,2));
RUN;

proc transpose data=ecadj out=ecadj2(drop=_:) prefix=ecadj;
    by usubjid paramcd;
    var ecadj;
RUN;

data ec4;
    merge ec3(in=a) ecadj2;
    by usubjid paramcd;
    if a;

    if avalc="Y" and not missing(ecadj1) then reason=catx(',', of ecadj:);
RUN;

** determine ASTDT (if <80% then start of the week window, if <5/7 only then the third 0 in the earliest 7-consecutive-day window);
data astdt;
    set ec_5_7b(drop=i);

    if sum(of day2-day8, 0)<5 then w1=2; *the start day of 7-consecutive-day condition for week1 is day 2;

    ** to determine the start day of the earliest 7-consecutive-day condition for week 4,8,12;
    array w4_day (14) day15-day28;
    array w8_day (14) day43-day56;
    array w12_day (14) day71-day84;

    w4=.;
    w8=.;
    w12=.;

    do i=1 to 8;
        if sum(0,w4_day[i],w4_day[i+1],w4_day[i+2],w4_day[i+3],w4_day[i+4],w4_day[i+5],w4_day[i+6])<5 and missing(w4) then w4=14+i;
        if sum(0,w8_day[i],w8_day[i+1],w8_day[i+2],w8_day[i+3],w8_day[i+4],w8_day[i+5],w8_day[i+6])<5 and missing(w8) then w8=42+i;
        if sum(0,w12_day[i],w12_day[i+1],w12_day[i+2],w12_day[i+3],w12_day[i+4],w12_day[i+5],w12_day[i+6])<5 and missing(w12) then w12=70+i;
    END;
RUN;

proc transpose data=astdt out=astdt2;
    by usubjid w:;
    var day:;
RUN;

data astdt2;
    set astdt2;
    length day 8.;
    day=input(strip(substr(_name_,4)), 8.);
    if missing(col1) and (.<w1<=day<=sum(w1,6) or .<w4<=day<=sum(w4,6) or .<w8<=day<=sum(w8,6) or .<w12<=day<=sum(w12,6));
    if 2<=day<=8 then week=1;
    else if 15<=day<=28 then week=4;
    else if 43<=day<=56 then week=8;
    else if 71<=day<=84 then week=12;
RUN;

proc sort data=astdt2;
    by usubjid week day;
RUN;

data astdt2;
    set astdt2;
    by usubjid week day;
    if first.week then zero=1;
    else zero+1;
RUN;

data astdt3(keep=usubjid paramcd day);
    set astdt2(where=(zero=3));
    %createCustomVars(adsDomain=adex, vars = paramcd);
    paramcd="TRTINW"||strip(put(week, best.));
RUN;

proc sort data=astdt3;
    by usubjid paramcd;
RUN;

data ice_final;
    merge ec4(in=a) astdt3;
    by usubjid paramcd;
    if a;

    %createCustomVars(adsDomain = adex, vars = astdt astdy parcat1 ice01fl icereas);
    parcat1="by eDiary";
    if avalc = "Y" then ice01fl = "Y";
    if ice01fl ="Y" then icereas = strip(reason);
    if comp_wk4<0.8 and paramcd="TRTINW4" then astdy=15;
    if comp_wk8<0.8 and paramcd="TRTINW8" then astdy=43;
    if comp_wk12<0.8 and paramcd="TRTINW12" then astdy=71;
    if missing(astdy) and avalc="Y" then astdy=day;
    if not missing(astdy) then astdt=astdy+trtsdt-1;
    format astdt date9.;
RUN;

/** Extra guidance from stat: after permanent discontinuation from treatment, there should be no ICE record of temporary treatment interruption **/
** get PD subjects from DS;
proc sort data=sp.ds out=pd_subj(keep=usubjid);
    where epoch="TREATMENT" and dsdecod^="COMPLETED" and missing(dsscat);
    by usubjid;
RUN;

** get last dosing date from ADSL.TRTEDT;
data ice_final(drop=trtedt randdt);
    merge ice_final(in=a) pd_subj(in=b) ads.adsl(keep=usubjid trtedt randdt);
    by usubjid;
    if a;

    if b and not missing(trtedt) then do;
        if (trtedt-randdt+1)<=1 and paramcd in ("TRTINW1" "TRTINW4" "TRTINW8" "TRTINW12") then delete;
        else if 1<(trtedt-randdt+1)<=14 and paramcd in ("TRTINW4" "TRTINW8" "TRTINW12") then delete;
        else if 14<(trtedt-randdt+1)<=42 and paramcd in ("TRTINW8" "TRTINW12") then delete;
        else if 42<(trtedt-randdt+1)<=70 and paramcd in ("TRTINW12") then delete;
    END;

    if b and missing(trtedt) then put "WARN" "NING:" usubjid "has permanent discontinued based on DS but no last dosing date available.";
RUN;

%MEND m_trtice;
