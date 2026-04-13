/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = d_adex);
/*
 * Purpose          : to re-program ADEX
 * Programming Spec :
 * Validation Level : 2 - Verification by Double Programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gmrpb (Fiona Yan) / date: 29AUG2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/d_adex.sas (gmrpb (Fiona Yan) / date: 18AUG2023)
 ******************************************************************************/
/* Changed by       : eokcw (Vijesh Shrivastava) / date: 12SEP2023
 * Reason           : updated DURW ANALCA1N category from <26 to <25 and >=26 to >=25
 ******************************************************************************/
/* Changed by       : gmrpb (Fiona Yan) / date: 24NOV2023
 * Reason           : total dose from CRF can be missing, remove some user warning
 ******************************************************************************/

%let adsDomain = ADEX;

proc sort data=ads.&adsDomain. out=&adsDomain.;
    by usubjid;
RUN;

*<*****************************************************************************;
*< Custom Derivation;
*<*****************************************************************************;

** PARAMCD = TRT;
** populate PARCAT1/AVAL;
proc sql;
    create table seq_max as
    select usubjid, max(exseq) as seq_max
    from &adsDomain.
    where cmiss(exstdtc,exendtc)<2
    group by usubjid;
QUIT;

data trt;
    merge &adsDomain.(in=a) ads.adsl(keep=usubjid trtedt) seq_max;
    by usubjid;
    if a;

    %createCustomVars(adsDomain = adex, vars = PARCAT1 AVAL)
    parcat1="by eCRF";
    aval=exdose;

    if exseq=seq_max and missing(exendtc) then aendt=trtedt;
RUN;

** treatment duration (weeks): PARAMCD = DURW - by phase (I,II,overall), based on CRF;
** populate APHASE/ASTDT/AENDT/PARCAT1/AVAL/PARAMTYP/TRTAN;
** SAP: Treatment duration will be defined as the number of days from the day of first study drug intake up to and;
** including the day of last study drug intake and will be summarized using descriptive statistics by treatment group, by study drug, and overall.;
proc sort data=sp.ec out=durw;
    where eccat="STUDY INTERVENTION" and cmiss(ecstdtc,ecendtc)<2 and missing(ECDOSMOD) and missing(ECADJ) and ecoccur='Y';
    by usubjid;
RUN;

data durw;
    set durw;
    ecstdt=input(ecstdtc, yymmdd10.);
    ecendt=input(ecendtc, yymmdd10.);
    format ecstdt ecendt date9.;
RUN;

proc transpose data=durw out=t_durw1(drop=_:) prefix=ecstdt;
    by usubjid;
    var ecstdt;
    id ecspid;
RUN;

proc transpose data=durw out=t_durw2(drop=_:) prefix=ecendt;
    by usubjid;
    var ecendt;
    id ecspid;
RUN;

data durw_crf;  *potential note about Missing values were generated as a result of performing an operation on missing values due to ongoing subject;
    merge t_durw1(in=ec1) t_durw2(in=ec2)
          ads.adsl(in=adsl keep=usubjid ph1edt ph2sdt trt01an trtedt);
    by usubjid;
    if ec1;

    ** If the date for end of exposure is not available in eCRF, the last day of drug intake from eDiary will be used to determine the end of exposure;
    if not missing(ecstdt1) and nmiss(ecendt1,ecstdt2,ecendt2)=3 then ecendt1=trtedt;
    else if not missing(ecstdt2) and missing(ecendt2) and ecstdt2<=trtedt then ecendt2=trtedt;

    %createCustomVars(adsDomain = adex, vars = PARAMCD PARCAT1 APHASE ASTDT AENDT AVAL TRTAN);
    paramcd="DURW";
    parcat1="by eCRF";

    ** Phase I;
    APHASE="Week 1-12";
    ASTDT=ecstdt1;
    AENDT=ifn(missing(ph2sdt),ecendt1,ph1edt);
    AVAL=(aendt-astdt+1)/7;
    if trt01an=100 then trtan=1;
    else if trt01an=101 then trtan=0;
    output;

    ** Phase II;
    if not missing(ph2sdt) then do;
        APHASE="Week 13-26";
        ASTDT=ph2sdt;
        AENDT=ecendt2;
        AVAL=(aendt-astdt+1)/7;
        trtan=1;
        output;
    END;

    ** Overall;
    if trt01an=100 then do; *100 - Elinzanetant 120mg;
        APHASE="Overall";
        ASTDT=ecstdt1;
        if not missing(ph2sdt) then AENDT=max(ecendt1,ecendt2, ph2sdt-1);
        else AENDT=ecendt1;
        AVAL=(aendt-astdt+1)/7;
        TRTAN=1;
        output;
    END;
    else if trt01an=101 then do; *101 - Placebo - Elinzanetant 120mg;
        APHASE="Overall";
        ASTDT=ecstdt1;
        AENDT=ifn(missing(ph2sdt),ecendt1,ph1edt);
        AVAL=(aendt-astdt+1)/7;
        trtan=0;
        output;

        if not missing(ph2sdt) then do;
            ASTDT=ph2sdt;
            AENDT=ecendt2;
            AVAL=(aendt-astdt+1)/7;
            trtan=1;
            output;
        END;
    END;
RUN;

data durw_crf;
    set durw_crf;
    if missing(aval) then do;
        put "WAR" "NING: USUBJID=" usubjid "APHASE=" aphase "still ongoing. Duration is temporally removed.";
        delete;
    END;
RUN;

data durw_crf;
    set durw_crf;
    %createCustomVars(adsDomain = adex, vars = PARCAT2);
    parcat2="by study drug";
    output;
    parcat2="by treatment group";
    call missing(trtan);
    output;
RUN;

proc sort data=durw_crf;
    by usubjid parcat1 parcat2 trtan aphase;
RUN;

data durw_crf;
    set durw_crf;
    by usubjid parcat1 parcat2 trtan aphase;
    retain aval_sum overall_astdt;

    if first.aphase then do;
        aval_sum=aval;
        order=1;
        overall_astdt=astdt;
    END;
    else do;
        aval_sum=aval_sum+aval;
        order=2;
    END;
RUN;

data durw_crf;
    set durw_crf;
    by usubjid parcat1 parcat2 trtan aphase order;
    if parcat2="by treatment group" and aphase="Overall" and order=2 then do;
        astdt=overall_astdt;
        aval=aval_sum;
    END;
    if last.aphase;
RUN;

** extent of exposure: Total Amount of Dose (mg)  + Actual Daily Dose (mg) - by phase (I,II,overall), based on CRF + eDiary;
** populate APHASE/PARCAT1/AVAL;
** SAP: The extent of exposure to elinzanetant will be summarized as the total amount of study drug intake in grams (in table, in dataset we use mg);
** and the average daily dose in mg using descriptive statistics per treatment group and overall. ;

** PARAMCD = TOTDOSE - based on CRF (DA);
** OASIS1: add below check due to DIL-DF#75;
proc freq data=sp.da noprint;
    table usubjid*dasmnum*datestcd/out=da_check;
RUN;

data _null_;
    set da_check;
    if count>1 then put "WARN" "ING: USUBJID=" USUBJID "DASMNUM=" DASMNUM "DATESTCD=" DATESTCD "has more than one entry. Need to add to DIL-DF#75.";
RUN;

proc sort data=sp.da out=da nodupkey;
    by usubjid dasmnum datestcd;
RUN;

proc transpose data=da out=totdose_da(drop=_:);
    by usubjid dasmnum;
    id datestcd;
    var dastresn;
RUN;

*? DIL DF#32 - Some records with DATESTCD=DISPAMT are with DADTC missing.;
*? Per tolu's response, this is due to ongoing data input. Should not be the case in the end.;
*? currently if missing date and PH2SDT is not missing, set to phase 2;
data da_date;
    set da(where=(datestcd="DISPAMT"));
    dadt=input(dadtc,yymmdd10.);
    keep usubjid dasmnum dadt;
    format dadt date9.;
RUN;

data totdose_crf;
    merge totdose_da da_date;
    by usubjid dasmnum;
RUN;

data totdose_crf2;
    merge totdose_crf(in=a) ads.adsl(keep=usubjid ph2sdt trt01an);
    by usubjid;
    if a;

    if missing(dispamt) then dispamt=0;
    if missing(lostamt) then lostamt=0;
    if missing(retamt) then retamt=0;
    %createCustomVars(adsDomain = adex, vars = PARAMCD PARCAT1 AVAL);
    paramcd="TOTDOSE";
    parcat1="by eCRF";
    aval=(dispamt-lostamt-retamt)*60;
    capsule=dispamt-lostamt-retamt;
RUN;

data totdose_crf3;
    set totdose_crf2;
    %createCustomVars(adsDomain = adex, vars = aphase);

    if dadt>=ph2sdt>. or (dadt=. and not missing(ph2sdt)) then aphase="Week 13-26";
    else do;
        aphase="Week 1-12";
        if trt01an=101 then aval=0;
    END;
    output;

    aphase="Overall";
    output;
RUN;

proc sql;
    create table totdose_crf_final as
    select usubjid, aphase, paramcd, parcat1, sum(aval) as AVAL, sum(capsule) as capsule
    from totdose_crf3
    group by usubjid, aphase, paramcd, parcat1;
QUIT;


** PARAMCD = TOTDOSE - based on eDiary;
data totdose_ediary;
    set sp.ec(where=(eccat="STUDY INTERVENTION, DIARY" and ecdose^=0 and ecoccur="Y"));

    ** if actual date= planned date or if actual date=planned+1 and time up to 2am ;
    ** THEN dosing date=planned date, otherwise dosing date = actual date;
    if index(ECSTDTC,'T')>0 then do;
        if not (input(scan(ECSTDTC,2,'T'),time5.)>input('02:00',time5.)) then ECSTDTC= put(input(scan(ECSTDTC,1,'T'),yymmdd10.)-1,yymmdd10.);
    END;

    ecstdt=input(ecstdtc,yymmdd10.);

    format ecstdt date9.;
    keep usubjid ecdose ecstdt;
RUN;

proc sort data=totdose_ediary;
    by usubjid;
RUN;

data totdose_ediary2;
    merge totdose_ediary(in=a) ads.adsl(keep=usubjid ph1sdt ph1edt ph2sdt ph2edt trt01an);
    by usubjid;
    if a;
RUN;

data totdose_ediary3;
    set totdose_ediary2;
    %createCustomVars(adsDomain = adex, vars = PARAMCD PARCAT1 AVAL aphase);
    paramcd="TOTDOSE";
    parcat1="by eDiary";
    aval=ecdose*60;

    if ecstdt>=ph2sdt>. then aphase="Week 13-26";
    else do;
        aphase="Week 1-12";
        if trt01an=101 then aval=0;
    END;
    output;

    APHASE="Overall";
    output;
RUN;

proc sql;
    create table totdose_ediary_final as
    select usubjid, aphase, paramcd, parcat1, ph1sdt, ph1edt, ph2sdt, ph2edt, sum(aval) as AVAL, sum(ecdose) as capsule, min(ecstdt) as ecstdt_first format=date9., max(ecstdt) as ecstdt_last format=date9.
    from totdose_ediary3
    group by usubjid, aphase, paramcd, parcat1, ph1sdt, ph1edt, ph2sdt, ph2edt;
QUIT;


** PARAMCD = ACDLYDS - based on CRF;
proc sql;
    create table acdlyds_crf as
    select usubjid, aphase, paramcd, parcat1, sum(aval)*7 as durd_crf
    from durw_crf
    where parcat2="by treatment group"
    group by usubjid, aphase, paramcd, parcat1;
QUIT;

data acdlyds_crf_final;
    merge acdlyds_crf(in=a drop=paramcd) totdose_crf_final(in=b);
    by usubjid aphase parcat1;
    paramcd="ACDLYDS";
    if nmiss(aval,durd_crf)=0 and durd_crf^=0 then aval=aval/durd_crf;
    else call missing(aval);

    if not a or not b then do;
        *put "WAR" "NING: USUBJID=" usubjid "APHASE=" aphase "PARCAT1=" parcat1 ", daily dose is not calculated due to either duration or total dose not available.";
        delete;
    END;
RUN;


** PARAMCD = ACDLYDS - based on eDiary;
proc sql;
    create table acdlyds_ediary as
    select *, max(ecstdt_last) as last_trt format=date9.
    from totdose_ediary_final
    group by usubjid;
QUIT;

data acdlyds_ediary_final;
    merge acdlyds_ediary(in=a) acdlyds_crf(in=b keep=usubjid aphase durd_crf);
    by usubjid aphase;
    if a;

    paramcd="ACDLYDS";
    if aphase="Overall" or (aphase="Week 1-12" and PH2SDT=.) then durd_ediary=ecstdt_last-max(ph1sdt,ecstdt_first)+1;
    else if aphase="Week 1-12" and PH2SDT^=. and last_trt>=PH2SDT then durd_ediary=ph1edt-max(ph1sdt,ecstdt_first)+1;
    else if aphase="Week 1-12" and PH2SDT^=. and last_trt<PH2SDT then durd_ediary=last_trt-max(ph1sdt,ecstdt_first)+1;
    else if aphase="Week 13-26" then durd_ediary=ecstdt_last-ph2sdt+1;

    if not missing(durd_crf) then aval=aval/durd_crf;
    else do;
        put "WAR" "NING: USUBJID=" usubjid "APHASE=" aphase "PARCAT1=" parcat1 ", daily dose is not calculated due to either duration or total dose not available.";
        delete;
    END;
RUN;

** treatment compliance (%) - further 3 groups - by phase (I,II,overall), based on CRF + eDiary;
** populate APHASE/PARCAT1/AVAL/AVALCA1N;
** SAP: The compliance (as percentage) will be calculated as: 100 * Number of capsules taken / Number of planned capsules;
** The number of planned capsules is calculated as: treatment duration * 2. All capsules, including the placebo capsules, will be counted.;
** For participants who withdraw prematurely from the study drug, compliance will be calculated up to the time of last dose.;
** The compliance will be summarized descriptively by treatment group and overall.;
** In addition, percentage of compliance will be categorized into 3 groups, less than 80%, 80 to 120% and greater than 120%, ;
** and the categories will be summarized by treatment group, by study drug, and overall. ;

** PARAMCD = COMPLPRC - based on CRF, eDiary;
data totdose_temp(keep=usubjid parcat1 aphase totcap);
    set totdose_crf_final totdose_ediary_final;
    totcap=capsule;
RUN;

data durd_temp(keep=usubjid parcat1 aphase durd);
    set acdlyds_crf_final(rename=(durd_crf=durd)) acdlyds_ediary_final(rename=(durd_crf=durd));
RUN;

proc sort data=totdose_temp;
    by usubjid parcat1 aphase;
RUN;

proc sort data=durd_temp;
    by usubjid parcat1 aphase;
RUN;

data complprc_trtgrp;
    merge totdose_temp(in=a) durd_temp(in=b);
    by usubjid parcat1 aphase;

    %createCustomVars(adsDomain = adex, vars = AVAL AVALCA1N parcat2 paramcd);
    parcat2="by treatment group";
    paramcd="COMPLPRC";
    if nmiss(totcap,durd)=0 and durd^=0 then aval=totcap*100/(2*durd);
    else do;
        *put "WAR" "NING: USUBJID=" usubjid "APHASE=" aphase "PARCAT1=" parcat1 "PARCAT2=" parcat2 ", compliance is not calculated due to either duration or total capsule not available.";
        delete;
    END;
    if .<round(aval,0.0000000000001)<80 then avalca1n=7;
    else if 80<=round(aval,0.0000000000001)<=120 then avalca1n=8;
    else if 120<round(aval,0.0000000000001) then avalca1n=9;
RUN;

data complprc_drug;
    merge complprc_trtgrp(in=a) ads.adsl(keep=usubjid trt01an);
    by usubjid;
    if a;
    parcat2="by study drug";
    %createCustomVars(adsDomain = adex, vars = trtan);

    if trt01an=100 then do;
        trtan=1;
        output;
    END;

    else if trt01an=101 then do;
        if aphase in ("Week 1-12" "Week 13-26") then do;
            if aphase="Week 1-12" then trtan=0;
            else if aphase="Week 13-26" then trtan=1;
            output;
            aphase="Overall";
            output;
        END;
    END;
RUN;

data complprc_drug;
    set complprc_drug;
    if missing(aval) then do;
        put "WAR" "NING: USUBJID=" usubjid "APHASE=" aphase "PARCAT1=" parcat1 "PARCAT2=" parcat2 ", compliance is not calculated due to either duration or total capsule not available.";
        delete;
    END;
RUN;

** ICE part;
%m_trtice;

** combine and add ADSNAME/STUDYID/ASTDY/AENDY/PARAMTYP info;
data final;
    set trt durw_crf totdose_crf_final totdose_ediary_final acdlyds_crf_final acdlyds_ediary_final complprc_trtgrp complprc_drug ice_final;
    studyid="&STUDY.";
    adsname="&adsDomain.";
    if paramcd^="TRT" then paramtyp="DERIVED";
RUN;

proc sort data=final;
    by usubjid;
RUN;

data final2;
    merge final(in=a) ads.adsl(keep=usubjid randdt);
    by usubjid;
    if a;

    if not missing(astdt) then astdy=astdt-randdt +(astdt>=randdt);
    if not missing(aendt) then aendy=aendt-randdt +(aendt>=randdt);

    ** per new request, add AVALCA1N for overall duration by treatment group (< 4 weeks, 4 - < 12 weeks, 12 - < 26 weeks, >= 26 weeks);
    if paramcd="DURW" and aphase="Overall" and parcat2="by treatment group" then do;
        if .z<aval<4 then avalca1n=21;
        else if 4<=aval<12 then avalca1n=22;
        else if 12<=aval<25 then avalca1n=23;
        else if 25<=aval then avalca1n=24;
    END;
RUN;

*<*****************************************************************************;
*< Late ADS processing;
*<*****************************************************************************;

data ADS.&adsDomain.;
    set final2(drop=aseq);

    ** update PARAMCD to deal with PARCAT issue;
    if paramcd="ACDLYDS" and parcat1="by eCRF" then paramcd="ACDDCRF";
    else if paramcd="ACDLYDS" and parcat1="by eDiary" then paramcd="ACDDDRY";
    else if paramcd="COMPLPRC" and parcat1="by eCRF" and parcat2="by study drug" then paramcd="CMPCRFDR";
    else if paramcd="COMPLPRC" and parcat1="by eCRF" and parcat2="by treatment group" then paramcd="CMPCRFGR";
    else if paramcd="COMPLPRC" and parcat1="by eDiary" and parcat2="by study drug" then paramcd="CMPDRYDR";
    else if paramcd="COMPLPRC" and parcat1="by eDiary" and parcat2="by treatment group" then paramcd="CMPDRYGR";
    else if paramcd="DURW" and parcat1="by eCRF" and parcat2="by study drug" then paramcd="DURWDR";
    else if paramcd="DURW" and parcat1="by eCRF" and parcat2="by treatment group" then paramcd="DURWGR";
    else if paramcd="TOTDOSE" and parcat1="by eCRF" then paramcd="TOTDSCRF";
    else if paramcd="TOTDOSE" and parcat1="by eDiary" then paramcd="TOTDSDRY";
RUN;

%late_ads_processing(adsDat = ADS.&adsDomain.)

%endprog()





