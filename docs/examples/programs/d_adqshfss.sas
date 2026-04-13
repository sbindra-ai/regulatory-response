/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = d_adqshfss);
/*
 * Purpose          : Derivation of ADQS HF digital diary and sleepiness scale
 * Programming Spec :
 * Validation Level : 2 - Verification by Double Programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gmrpb (Fiona Yan) / date: 06OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/d_adqshfss.sas (gmrpb (Fiona Yan) / date: 22JUL2023)
 ******************************************************************************/

%let adsDomain = ADQSHFSS;

*<*****************************************************************************;
*< early ADS processing;
*<*****************************************************************************;

* run the early_ads in work so we don't overwrite the ADS dataset twice;

%early_ads_processing(
    adsDat = &adsDomain.
  , adsLib = work
)

*<*****************************************************************************;
*< temp fix for missing HFDB202 but non-missing HFDB202A/B/C/D case;
*<*****************************************************************************;
proc sort data=&adsDomain. out=hfdb202;
    where qstestcd="HFDB202";
    by usubjid qsdtc qsscat;
RUN;

proc sort data=&adsDomain. out=hfdb202sub nodupkey;
    where qstestcd in ('HFDB202B' 'HFDB202D' 'HFDB202A' 'HFDB202C');
    by usubjid qsdtc qsscat;
RUN;

** add dummy record;
data tempfix;
    merge hfdb202(in=a keep=usubjid qsdtc qsscat) hfdb202sub(in=b drop=qsseq qsgrpid);
    by usubjid qsdtc qsscat;
    if not a and b;
    put "WARN" "ING: Reported to DIL-DF#107. USUBJID=" usubjid "QSDTC=" QSDTC "QSSCAT=" QSSCAT "HFDBD202A/B/C/D is available but not HFDB202.";
    qstestcd="HFDB202";
    qstest="HFDB2-Have Any Hot Flashes";
    qsorres='Y';
    qsstresc='Y';
    qsstresn=.;
    tempfix='Y';
RUN;


/*< Split ADQS data into two keep here HFDD and Sleep scale */

data &adsDomain.;
    set &adsDomain. tempfix;
    attrib DOMAIN format=8.;
    if qscat not in ('TWICE DAILY HOT FLASH DIARY V2.0' 'SLEEPINESS SCALE V1.0') then delete ;

    if qscat="TWICE DAILY HOT FLASH DIARY V2.0" and qsscat="MORNING HOT FLASH DIARY" then atptn=99999920.01;
    else if qscat="TWICE DAILY HOT FLASH DIARY V2.0" and qsscat="EVENING HOT FLASH DIARY" then atptn=99999920.03;
    else if qscat="SLEEPINESS SCALE V1.0" and qsevintx="MORNING" then atptn=99999920.01;
    else if qscat="SLEEPINESS SCALE V1.0" and qsevintx="AFTERNOON" then atptn=99999920.02;
    else if qscat="SLEEPINESS SCALE V1.0" and qsevintx="EVENING" then atptn=99999920.03;

    if not missing (qsorres) then do;
        if anyfirst(qsorres) = 0 and index (qsorres , ":") = 0 then do;
            AVAL = input(compress(qsorres," :.-''" ,'a'), 12.);
        END;
        if anyfirst(qsorres) not in (0,1,2) and index(qsorres, ":") = 2 then do;
            AVAL = input(compress(scan(qsorres,index(qsorres, ":") = 2)," :.-''",'a'), 12.);
        END;

        if anyfirst(qsorres) in (0,1) then AVALCN = strip(qsorres);
        if index(qsorres,":") = 2 then AVALCN = substr(qsorres,index(qsorres,":")+1);
        else if index(qsorres,":") = 0 then AVALCN = strip(qsorres);
    END;

    *Macros were using avalc for their calculation *;
    avalc = strip(put(aval ,best.));
run;

*<*****************************************************************************;
*< Detect and flag duplicate records - DUPFL=Y;
*<*****************************************************************************;
** keep in mind that if answer N to HFDB202, HFDB202A/B/C/D don't have to be answered. if answer Y to HFDB202, HFDB202A/B/C/D are required to be answered;
** so simple nodupkey to QSTESTCD and more vars won't work. In case the first obs is N and second obs is Y;
proc freq data=&adsDomain. noprint;
    table qstestcd*qstest*usubjid*qsscat*qsdtc*QSEVINTX/out=dup_check(drop=percent);
RUN;

data dup_check2;
    set dup_check;
    where count>1 and qstestcd not in ('HFDB202B' 'HFDB202D' 'HFDB202A' 'HFDB202C');
RUN;

proc freq data=&adsDomain. noprint;
    table qstestcd*usubjid*qsscat*qsdtc*QSEVINTX*QSASSDTC/out=dup_list(drop=percent count);
RUN;

data dup_combine;
    merge dup_check2(in=a) dup_list;
    by qstestcd usubjid qsscat qsdtc qsevintx;
    if a;
RUN;

data dup_combine(drop=count qstest);
    set dup_combine;
    by qstestcd usubjid qsscat qsdtc qsevintx qsassdtc;
    if not (first.qsevintx) then dupfl="Y";
    else delete;
RUN;

data dup_combine;
    set dup_combine;
    output;
    if qstestcd="HFDB202" then do;
        qstestcd="HFDB202A";output;
        qstestcd="HFDB202B";output;
        qstestcd="HFDB202C";output;
        qstestcd="HFDB202D";output;  *even populate for morning, will be taken care of by "if a" later;
    END;
RUN;

proc sort data=dup_combine;
    by usubjid qstestcd qsscat qsdtc qsevintx qsassdtc;
RUN;

proc sort data=&adsDomain.;
    by usubjid qstestcd qsscat qsdtc qsevintx qsassdtc;
RUN;

data &adsDomain.;
    merge &adsDomain.(in=a) dup_combine;
    by usubjid qstestcd qsscat qsdtc qsevintx qsassdtc;
    if a;
RUN;

*<*****************************************************************************;
*< Adjustment of analysis visit;
*<*****************************************************************************;

**get flag for subjects who enter post-treatment period;
proc sort data=ads.adds out=post_trt_info(keep=usubjid);
    where dsnext="POST-TREATMENT";
    by usubjid;
RUN;

**get flag for subjects who completed treatment EPOCH;
proc sort data=ads.adds out=comp_trt_subj(keep=usubjid);
    where EPOCH="TREATMENT" and missing(DSSCAT) and dsdecod="COMPLETED";
    by usubjid;
RUN;

**get flag for subjects who early discontinued from treatment EPOCH;
proc sort data=ads.adds out=ed_trt_subj(keep=usubjid astdy);
    where EPOCH="TREATMENT" and missing(DSSCAT) and dsdecod^="COMPLETED";
    by usubjid;
RUN;

data &adsDomain.;
    merge &adsDomain.(in=a)
          post_trt_info(in=b)
          comp_trt_subj(in=c)
          ed_trt_subj(in=d rename=(astdy=ed_day))
          ads.adsl(keep=usubjid trtedt randdt);
    by usubjid;
    if a;

    ** calculate the diary day/date of records;
    if qstestcd in ('HFDB202A' 'HFDB202B' 'HFDB202C' 'HFDB201' 'HFDB202' 'HFDB202D') and atptn=99999920.01 then do;
        if not missing(ady) then diary_ady=ady-1;
        if diary_ady=0 then diary_ady=-1;
    END;
    else diary_ady=ady;
    if .z<diary_ady<0 then diary_adt=diary_ady+randdt;
    else if diary_ady>0 then diary_adt=diary_ady+randdt-1;

    ** calculate the date of end day of last dosing week, this will be used for subjects who don't enter post-treatment period;
    if nmiss(trtedt,randdt)=0 then trtedy=trtedt-randdt+(trtedt>=randdt);
    if not missing(trtedy) then sch_edy=ceil(trtedy/7)*7;

    ** flag for records of subjects who enter post-treatment period;
    if b then post_trt_subj='Y';

    ** flag for (non-follow-up) scheduled visits for all subjects;
    ** (1) all records for subjects who enter post-treatment EPOCH;
    ** (2) all records for ongoing subjects who are still in treatment EPOCH;
    ** (3) all records on or before the last dosing week for subjects who completed treatment EPOCH or who early discontinued after week 12 and didn't enter post-treatment period;
    ** (4) all records on or before day 84 for subjects who early discontinued before week 12 and didn't enter post-treatment period;
    if b or
       not (c or d) or
       ((c or (d and ed_day>84 and not b)) and .z<diary_ady<=sch_edy) or
       ((d and ed_day<=84 and not b) and .z<diary_ady<=84)
       then sch_flg='Y';

    ** calculate the follow-up day (diary day version) since last dosing date for all subjects;
    if diary_adt>trtedt>.z then fup_ady=diary_adt-trtedt;

    ** flag for records that later to be duplicated to derived 4-week artificial follow-up for subjects who enter post-treatment period;
    if b and 1<=fup_ady<=28 then do;
        post_trt_atfc_fup='Y';
        atfc_avisitn=ceil(fup_ady/7)*10+700000;
    END;

    ** flag for real follow-up of subjects who don't enter post-treatment period;
    if not b and (c or d) and diary_adt>trtedt>.z then do;
        real_fup_obs='Y';
        real_fup_avisitn=ceil(fup_ady/7)*10+700000;
    END;

    ** flag for records that would work as both real follow-up and scheduled visits for subjects who don't enter post-treatment period;
    if sch_flg='Y' and real_fup_obs='Y' then real_fup_dup='Y';
RUN;


data &adsDomain.;
    set &adsDomain.;
    ** AVISITN will be assigned based on diary day;
    ** in final data, for non-derived parameters, AVISIT will be set to blank;
    ** one reason AVISIT is not saved in final AVISIT for non-derived parameter is that - day 8 evening and day 9 morning will be used for both week 1 and 2;
    ** A diary day for the calculation of the frequency and severity of HF consists of the evening entry (Evening Hot Flash eDIARY) and the morning entry (Morning Hot Flash eDIARY) of the subsequent day.;
    ** A day will be considered available for the calculation of the frequency and severity of HF, if at least the evening or the morning entry (of the subsequent day) is not missing.;

    ** step1: assign AVISITN for (non-follow-up) scheduled visits based on diary day;
    if diary_ady ne . and sch_flg='Y' then do;
        if -14<= diary_ady < 1 then AVISITN=5;
        else if 2<= diary_ady<= 7 then AVISITN=10;    *diary_ady=8 will be added later for avisitn=10;
        ** 260 instead of 600000 will be used. Set to Week 26 instead of EOT based on TLF shell;
        ** Create week 27,28 and so on to cover the gap between week 26 and week of last dosing, those visits will be present it in listing, but not in table;
        else if diary_ady>7 then AVISITN=ceil(diary_ady/7)*10;
    END;
RUN;

/** repeat day 8 evening and day 9 morning record to derive HFDD parameters and assign AVISITN **/
/** repeat day 8 record to derive SS parameters and assign AVISITN **/
/** repeat post_trt_atfc_fup='Y' records for artificial follow-up visits of subjects who enter post-treatment period and assign AVISITN **/
/** repeat real_fup_dup='Y' records for real follow-up visits of subjects who don't enter post-treatment period and assign AVISITN **/

data &adsDomain.;
    set &adsDomain.;

    ** step2: assign AVISITN for real follow-up visits based on diary day, except the real_fup_dup='Y' part that will be added later;
    if real_fup_obs='Y' and real_fup_dup^='Y' then avisitn=ceil(fup_ady/7)*10+700000;
    output;

    if qstestcd in ('HFDB202A' 'HFDB202B' 'HFDB202C' 'HFDB201' 'HFDB202' 'HFDB202D') and
       ((ady=8 and atptn=99999920.03) or (ady=9 and atptn=99999920.01)) then do;
           remove_flag="Y"; *those records need to be removed in the end;
           avisitn=10;  *add day 8 evening and day 9 morning record for week1;
           output;
    END;

    if qstestcd="SLSB0101" and ady=8 then do;
        remove_flag="Y"; *those records need to be removed in the end;
        avisitn=10;  *add day 8 record for week1;
        output;
    END;

    if post_trt_atfc_fup='Y' then do;
        remove_flag="Y"; *those records need to be removed in the end;
        avisitn=atfc_avisitn;  *add artificial follow-up;
        output;
    END;

    if real_fup_dup='Y' then do;
        remove_flag="Y"; *those records need to be removed in the end;
        avisitn=real_fup_avisitn;   *add real follow-up duplicate part in week of last dosing;
        output;
    END;
RUN;

** create intermediate ADT for diary day purpose;
data &adsDomain.;
    set &adsDomain.;
    adt_ori=adt;
    if qstestcd in ('HFDB202A' 'HFDB202B' 'HFDB202C' 'HFDB201' 'HFDB202' 'HFDB202D') and not missing(avisitn) and atptn=99999920.01 then adt=adt_ori-1;
RUN;

***** Add Frequency of hot flash and sever of daily hot flash ****;
%m_create_qs_sleepiness();
%m_create_qs_daily_awake();
%m_create_qs_daily_sleep();
%m_create_qs_daily_freq_all();
%m_create_qs_daily_freq();
%m_create_qs_daily_sev();

/** restore ADT and remove AVISITN info for non-derived parameters, remove repeated records **/
data &adsDomain.;
    set &adsDomain.;
    if remove_flag="Y" and paramtyp^="DERIVED" then delete;
    if qstestcd in ('HFDB202A' 'HFDB202B' 'HFDB202C' 'HFDB201' 'HFDB202' 'HFDB202D') then adt=adt_ori;
    if paramtyp^="DERIVED" then call missing(avisitn);
RUN;

/** add dummy records - should be based on FAS **/
** var to be included: ;
proc freq data=&adsDomain. noprint;
    where PARAMTYP='DERIVED';
    table adsname*studyid*qstestcd*paramtyp*parcat1/ out=dummy_avisitn(drop=count percent);
RUN;

proc sort data=ads.adsl out=fas(keep=usubjid);
    where fasfl='Y';
    by usubjid;
RUN;

proc sql;
    create table dummy_avisitn2 as
    select a.*, b.usubjid
    from dummy_avisitn as a join fas as b
    on 1;
QUIT;

data dummy_avisitn3(drop=i);
    set dummy_avisitn2;
    do i=1 to 12;
        avisitn=i*10;
        output;
    END;
RUN;

proc sort data=&adsDomain.;
    by adsname studyid usubjid qstestcd paramtyp parcat1 avisitn;
RUN;

proc sort data=dummy_avisitn3;
    by adsname studyid usubjid qstestcd paramtyp parcat1 avisitn;
RUN;

data &adsDomain.;
    merge &adsDomain.(in=a) dummy_avisitn3(in=b);
    by adsname studyid usubjid qstestcd paramtyp parcat1 avisitn;
    if b and not a then dummy_fl='Y';   *indicate the records are dummy one;
RUN;

** FY: ADT/ADY for derived PARAMCDs is updated to theoretical end of week in d_adqshfss per stat request;
** "Stats: Use date of theoretical end of week (diary day version), i.e. Date of Day 8 (for week 1), Day 14 (for week 2), etc...";
DATA &adsDomain.;
    merge &adsDomain.(drop=randdt in=a) ads.adsl(keep=usubjid randdt);
    by usubjid;
    if a;

    if paramtyp="DERIVED" then do;
        if avisitn=5 then ady=-1;
        else if avisitn=10 then ady=8;
        else if 20=<avisitn<700000 then ady=avisitn/10*7;
        else if avisitn>=700000 then ady=ceil(fup_ady/7)*7+trtedy;

        if ady=-1 then adt=randdt+ady;
        else adt=randdt+ady-1;
    END;

    %createCustomVars(adsDomain=adqshfss, vars=PARAMCD ABLFL);
    PARAMCD = QSTESTCD;
    if AVISITN=5 and PARAMTYP='DERIVED' and not missing(AVAL) then ABLFL='Y';

   *Reset qsseq to missing for all derived paramcd;
   if paramtyp="DERIVED" then qsseq=.;
RUN;

*< Criteria variable for HFDD;

data base(keep=usubjid qstestcd base);
    set &adsDomain.;
    if ablfl='Y';
    if aval ne . then do;
        base=aval;
    END;
RUN;

proc sort data=base;
    by usubjid qstestcd;
    where base ne .;
RUN;

proc sort data=&adsDomain.;
    by usubjid qstestcd ;
RUN;

*Bringing AVALC back*;

DATA &adsDomain.;
      set &adsDomain. (drop = avalc);
      if paramtyp ^= "DERIVED" then avalc = strip(avalcn) ;
run;

data &adsDomain.;
    merge &adsDomain. base;
    %createCustomVars(adsDomain=adqshfss, vars=chg pchg);

    by usubjid qstestcd ;
    if nmiss(aval, base) = 0 then do;
        chg = aval - base;
        if base^=0 then pchg = ((aval - base)/base) * 100;
    END;
RUN;


data &adsDomain.;
    set &adsDomain.;

    %createCustomVars(adsDomain=adqshfss, vars=CRIT1 CRIT1FL);

    if qstestcd in ('HFDB998') then do;
        * 50% reduction ;
        CRIT1 = 'At least 50% reduction in mean daily frequency';
        if pchg ne . then do;
            if . < pchg <= -50 then CRIT1FL= 'Y';
            else CRIT1FL= 'N';
        end;
    END;
RUN;

*<*****************************************************************************;
*< Add ANL04FL for descriptive table display purpose
*< + remove tempfix dummy record
*<*****************************************************************************;
data &adsDomain.;
    set &adsDomain.;
    if tempfix="Y" and missing(paramtyp) then delete;

    %createCustomVars(adsDomain=adqshfss, vars=ANL04FL);
    if paramtyp="DERIVED" and not missing(aval) then do;
        if 700040>=avisitn>=700000 then anl04fl="Y";
        else if avisitn<700000 and .z<ady-6<=trtedy or trtedy=. then anl04fl="Y";
    END;
RUN;

*<*****************************************************************************;
*< Add ICE flag: ANL01FL-ANL03FL and output to ADS;
*<*****************************************************************************;

%m_create_qs_ice_hfss();

*<*****************************************************************************;
*< Late ADS processing;
*<*****************************************************************************;

%late_ads_processing(adsDat = ADS.&adsDomain.)

%endprog();

