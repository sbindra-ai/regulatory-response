
/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/Pool  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = d_adsl);
/*
 * Purpose          : Derivation of ADSL
 * Programming Spec :
 * Validation Level : 2 - Verification by Double Programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : eokcw (Vijesh Shrivastava) / date: 22SEP2022
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : gmrpb (Fiona Yan) / date: 21AUG2023
 * Reason           : Add condition .z < age when deriving age groups
 *                    Remove unnecessary commented out code
 *                    Update %iniprog parameter
 ******************************************************************************/
/* Changed by       : gmrnq (Susie Zhang) / date: 05SEP2023
 * Reason           : Two records in DS, reported in DIL-DF#101, tempoary fix the program
 ******************************************************************************/
/* Changed by       : eokcw (Vijesh Shrivastava) / date: 12SEP2023
 * Reason           : changed DCSREAS to propcase
 ******************************************************************************/
/* Changed by       : gmrpb (Fiona Yan) / date: 06DEC2023
 * Reason           : add 0=missing for BMIGR1N
 ******************************************************************************/

%let adsDomain = ADSL;

*<*****************************************************************************;
*< early ADS processing;
*<*****************************************************************************;

/**================================================================================================================;*/
/** Bring in Exposure data with non missing EXSTDTC to facilitate standard macro working properly*/
/** _adamap_create_adsl_trtdt assumes all EXSTDTC will be non missing otherwise it picks missing as fist obs;
/*=================================================================================================================;*/

data ex;
    set sp.ex;
    where exstdtc ne '';
RUN;


%early_ads_processing(adsDat = &adsDomain.)

** need to remove TRT02AN TRT02PN as an extra step;
data &adsDomain.;
    set &adsDomain.;
    drop TRT02AN TRT02PN;
RUN;

/**** Custom Derivation;*/

** derive TRTEDT: If the date for end of exposure is not available in eCRF, the last day of drug intake from eDiary will be used to determine the end of exposure.;
proc sort data=sp.ex out=ex_exendtc;
    where not missing(exstdtc);
    by usubjid exseq;
RUN;

data ex_exendtc;
    set ex_exendtc;
    by usubjid exseq;
    if last.usubjid;
RUN;

proc sort data=sp.ec out=ec_exendtc;
    where eccat="STUDY INTERVENTION, DIARY" and ecdose>0 and ecoccur='Y';
    by usubjid ecstdtc;
RUN;

data ec_exendtc;
    set ec_exendtc;
    ** if actual date= planned date or if actual date=planned+1 and time up to 2am ;
    ** THEN dosing date=planned date, otherwise dosing date = actual date;
    if index(ECSTDTC,'T')>0 then do;
        if not (input(scan(ECSTDTC,2,'T'),time5.)>input('02:00',time5.)) then ECSTDTC= put(input(scan(ECSTDTC,1,'T'),yymmdd10.)-1,yymmdd10.);
    END;
RUN;

proc sort data=ec_exendtc;
    by usubjid ecstdtc;
RUN;

data ec_exendtc;
    set ec_exendtc;
    by usubjid ecstdtc;
    if last.usubjid;
RUN;

proc sort data=sp.ds out=non_ongoing(keep=usubjid) nodupkey;
    where epoch="TREATMENT" and missing(dsscat);
    by usubjid;
RUN;

data &adsDomain.(drop=exendtc ecstdtc exstdtc);
    merge &adsDomain.(in=a) ex_exendtc(keep=usubjid exendtc exstdtc) ec_exendtc(keep=usubjid ecstdtc) non_ongoing(in=b);
    by usubjid;
    if a;

    %createCustomVars(adsDomain=adsl, vars=trtedt);
    if not missing(exendtc) then trtedt=input(exendtc, yymmdd10.);
    else if not missing(ecstdtc) and scan(exstdtc,1,'T')>scan(ecstdtc,1,'T')>'' then trtedt=input(scan(exstdtc,1,'T'), yymmdd10.);
    else if not missing(ecstdtc) then trtedt=input(scan(ecstdtc,1,'T'), yymmdd10.);

    ** per team decision: for ongoing subjects, set TRTEDT to missing;
    if not b then call missing(trtedt);
RUN;


*================================================================================================================;
*  derive population variables ;
*================================================================================================================;

proc sql;
   create table enrol as select unique usubjid from sp.dm
      where rficdtc ^= ' '  order by usubjid;

   create table randd as select unique usubjid from sp.ds
      where dsdecod = 'RANDOMIZED' and not missing(randno) order by usubjid;

   create table saf as select unique usubjid from sp.dm
     where RFXSTDTC ^= ' '  order by usubjid;

   create table _sleep1 as select unique usubjid from sp.ds
     where dsdecod = 'INFORMED CONSENT OBTAINED' and DSTERM = "Informed consent for monitoring device" order by usubjid;

   create table _sleep2 as select unique usubjid from sp.xk
     where xkstat="" order by usubjid;

   create table _compl_trt as select unique usubjid from sp.ds
    where dsdecod = "COMPLETED" and dscat = "DISPOSITION EVENT" and EPOCH = "TREATMENT" order by usubjid;

   create table _compl_fup as select unique usubjid from sp.ds
   where dsdecod = "COMPLETED" and dscat = "DISPOSITION EVENT" and EPOCH = "FOLLOW-UP" order by usubjid;

    create table _exnyovln as select unique usubjid from sp.ex
    where not missing(exstdtc) order by usubjid;
quit;


*================================================================================================================;
* Smoking history ;
*================================================================================================================;

proc sort data=sp.su out=su(KEEP=USUBJID SUNCF);
   where upcase(sucat) = 'TOBACCO' and not missing(SUNCF);
   by usubjid suncf;
RUN;

** alphabetical order will take care of priority CURRENT>FORMER>NEVER;;
proc sort data=su nodupkey;
    by usubjid;
RUN;


*================================================================================================================;
* Education level ;
*================================================================================================================;

proc sort data=sp.sc out=edu(keep= usubjid scorres);
    by usubjid;
    where sctestcd="EDULEVEL";
RUN;

*================================================================================================================;
* Disposition ;
*================================================================================================================;

proc sort data=sp.ds out=ds(keep=usubjid DSDECOD DSSCAT EPOCH DSSTDTC DSSUBDEC) nodupkey;
    by usubjid DSSTDTC ;
    where dsdecod not in ("COMPLETED","SCREEN FAILURE") and dscat in ("DISPOSITION EVENT" "")
          and EPOCH ^= "SCREENING" and DSSCAT ne "INFORMED CONSENT"
          and DSSUBDEC not in ("CONTINUE WITH SCHEDULED VISITS/ PROCEDURES" "CONTINUE WITH PHONE CONTACTS REPLACING SITE VISITS");
RUN;

proc freq data=ds noprint;
    table usubjid/out=ds_check;
RUN;

data _null_;
    set ds_check(where=(count>1));
    put "WAR" "NING: USUBJID=" usubjid "has wired DS data regarding DSSUBDEC. Temp fix is applied and reported to DIL-DF#101";
RUN;

data ds;
    set ds;
    by usubjid dsstdtc;
    if last.usubjid;
RUN;

*================================================================================================================;
* Collect reason for subjects excluded from relevant population from SP.XI;
*================================================================================================================;
proc sort data=sp.xi out=xi nodupkey;
    by usubjid xitestcd XISTRESC;
RUN;

proc freq data=xi noprint;
    table usubjid*xitestcd/out=xistresc_count;
RUN;

data _null_;
    set xistresc_count;
    if count>1 then put "WARN" "ING: USUBJID=" USUBJID "XITESTCD=" XITESTCD "has more than one XISTRESC.";
RUN;

proc sort data=xi nodupkey;
    by usubjid xitestcd;
RUN;

data xi_saf xi_fas xi_sla;
    set xi;
    if xitestcd="SAFETY" then output xi_saf;
    if xitestcd="FULLSET" then output xi_fas;
    if xitestcd="DES" then output xi_sla;
    keep usubjid XISTRESC;
RUN;

*================================================================================================================;
* Merge all variables together;
*================================================================================================================;

data &adsDomain. (drop=suncf scorres  DSDECOD EPOCH DSSTDTC DSSUBDEC );
    merge &adsDomain.(in=a) enrol(in=enrol) randd(in=rand) saf(in=saf) _sleep1(in=sleep1) _sleep2(in=sleep2) su edu
          _compl_trt(in=compl_trt) _compl_fup(in=compl_fup) ds _exnyovln(in=_exnyovln)
          xi_saf(rename=(XISTRESC=XISTRESC_saf))
          xi_fas(rename=(XISTRESC=XISTRESC_fas))
          xi_sla(rename=(XISTRESC=XISTRESC_sla));
    by usubjid;
    if a;

    * _exnyovln;
    %createCustomVars(adsDomain=adsl, vars=exnyovln);
    if _exnyovln=1 then exnyovln=1;
    else exnyovln=0;

    * AGE group, SAP 6.6.1;
    %createCustomVars(adsDomain=adsl, vars=agegr1n);
    if .z < age < 40 then agegr1n = 11;
    else if age >= 40 and age <=49 then agegr1n = 12;
    else if age >= 50 and age <=59 then agegr1n = 13;
    else if age >= 60 and age <=65 then agegr1n = 14;
    else if age > 65 then agegr1n = 15;

    * Analysis set flag variables;
    %createCustomVars(adsDomain=adsl, vars=enrlfl randfl saffl fasfl slasfl complfl SAFEXRE1 FASEXRE1 SLAEXRE1);
    if enrol then ENRLFL="Y";
    else ENRLFL="N";
    if rand then do;
        randfl="Y"; fasfl="Y";
    end;
    else do;
        randfl="N"; fasfl="N";
    end;

    if saf then saffl="Y";
    else saffl="N";

    if sleep1 and sleep2 and rand then slasfl="Y";
    else slasfl="N";

    if compl_trt and compl_fup then complfl="Y";
    else complfl="N";

    * Exclusion reasons;
    %createCustomVars(adsDomain=adsl, vars=safexre1 fasexre1 slaexre1);
    SAFEXRE1 = strip(XISTRESC_saf);
    FASEXRE1 = strip(XISTRESC_fas);
    SLAEXRE1 = strip(XISTRESC_sla);

    * Region;
    %createCustomVars(adsDomain=adsl, vars=region1n);
    if country in ('USA' 'CAN') then region1n = 3;
    else  region1n = 9;

    * Tobacco use;
    %createCustomVars(adsDomain=adsl, vars=SMOKHXN);
    if suncf='NEVER' then SMOKHXN=1;
    else if suncf='FORMER' then SMOKHXN=2;
    else if suncf='CURRENT' then SMOKHXN=3;

    * Education level;
    %createCustomVars(adsDomain=adsl, vars=EDULEVEL);
    EDULEVEL = strip(scorres);

    * Birth date (year);
    %createCustomVars(adsDomain=adsl, vars=BRTHDT);
    BRTHDT = input(brthdtc, 4.);

    * Discontinuation from study;
    %createCustomVars(adsDomain=adsl, vars=DCSREAS);
    DCSREAS = propcase(DSDECOD);


    * Baseline BMI group;
    %createCustomVars(adsDomain=adsl, vars=bmigr1n);
    if bmibl >= 30 then bmigr1n = 4;
    else if bmibl >= 25 and bmibl < 30 then bmigr1n = 3;
    else if bmibl >= 18.5 and bmibl < 25 then bmigr1n = 2;
    else if . < bmibl < 18.5 then bmigr1n = 1;
    else if missing(bmibl) then bmigr1n = 0;
RUN;

*================================================================================================================;
* Add subgroup variables;
*================================================================================================================;

%m_create_subgroup();


*================================================================================================================;
* Add COVID pandemic variables ;
*================================================================================================================;

%m_create_covid();

*================================================================================================================;
* Add Phase1 and Phase2 start and end date.
*
* Phase1 starts: randomization (as the first dose will be taken on site, this should match the data in Rave);
* Phase1 ends: first day of drug 2 intake - 1 day based on the eCRF entry (this is for participants who stayed in the study for at least 12 weeks and received the part two drug)
*             [the Week 12 assessment date or the post treatment phase end date, whichever is earlier
*                (for participants who discontinued from study drug but agreed to complete the assessments until Week 12)
*              or study drug discontinuation date or EOT assessment date whichever is later
*                (for participants who discontinued from randomized drug and decided to go to the follow up period or withdraw from the study)];

* Phase2 starts: first day of part 2 drug intake (identified based on the eCRF entry).;
* Phase2 ends: end of treatment period date (for participants who completed the treatment period) or
            the study drug discontinuation date or EOT assessment date whichever is later (for participants who discontinue from treatment/study prematurely during the second phase)
*================================================================================================================;

* bring in scheduled visit date for week 12 and EOT assessment date;
data sv;
    set sp.sv;
    format svendt date9.;
    svendt = input(svendtc, ?? e8601da.);
RUN;

proc sort data=sv out=sv_w12(keep=usubjid svendt rename=(svendt=svenwk12));
    by usubjid;
    where visitnum=30;
RUN;

proc sort data=sv out=sv_eot(keep=usubjid svendt rename=(svendt=sveneot));
    by usubjid;
    where visitnum=600000;
RUN;


* bring in treatment period end date (for early discontinuation) from DS and next EPOCH info;
proc sort data=sp.ds out=ds_et(keep=usubjid dsstdtc dsnext) nodupkey;
    by usubjid;
    where epoch='TREATMENT' and dscat='DISPOSITION EVENT' and dsdecod ne 'COMPLETED' and dsscat^="INFORMED CONSENT";
RUN;

data ds_et(drop=dsstdtc);
    set ds_et;
    format DSSTDT_et date9.;
    DSSTDT_et = input(dsstdtc, ?? e8601da.);
RUN;

* bring in treatment period end date (for treatment completer) from DS;
proc sort data=sp.ds out=ds_cmpl(keep=usubjid dsstdtc) nodupkey;
    by usubjid;
    where epoch='TREATMENT' and dscat='DISPOSITION EVENT' and dsdecod eq 'COMPLETED' and dsscat^="INFORMED CONSENT";
RUN;

data ds_cmpl(drop=dsstdtc);
    set ds_cmpl;
    format DSSTDT_cmpl date9.;
    DSSTDT_cmpl = input(dsstdtc, ?? e8601da.);
RUN;

* bring in post treatment phase end date;
proc sort data=sp.ds out=ds_pt(keep=usubjid dsstdtc) nodupkey;
    by usubjid;
    where epoch='POST-TREATMENT' and missing(dsscat);
RUN;

data ds_pt(drop=dsstdtc);
    set ds_pt;
    format DSSTDT_pt date9.;
    DSSTDT_pt = input(dsstdtc, ?? e8601da.);
RUN;


* bring in part 1 drug and part 2 drug exposure info from EC;
proc sort data=sp.ec out=ec1(keep=usubjid ecendtc);
    where eccat="STUDY INTERVENTION" and missing(ECDOSMOD) and missing(ECADJ) and ecoccur='Y' and cmiss(ecstdtc,ecendtc)<2 and ecspid="1";
    by usubjid;
RUN;

data ec1(drop=ecendtc);
    set ec1;
    format p1_ecendt date9.;
    p1_ecendt = input(ecendtc, ?? e8601da.);
RUN;

proc sort data=sp.ec out=ec2(keep=usubjid ecstdtc ecendtc);
    where eccat="STUDY INTERVENTION" and missing(ECDOSMOD) and missing(ECADJ) and ecoccur='Y' and cmiss(ecstdtc,ecendtc)<2 and ecspid="2";
    by usubjid;
RUN;

data ec2(drop=ecstdtc ecendtc);
    set ec2;
    format p2_ecstdt p2_ecendt date9.;
    p2_ecstdt = input(ecstdtc, ?? e8601da.);
    p2_ecendt = input(ecendtc, ?? e8601da.);
RUN;


data &adsDomain. (drop=svenwk12 sveneot dsnext dsstdt_et dsstdt_cmpl dsstdt_pt p1_ecendt p2_ecendt p2_ecendt);
   merge &adsDomain.(in=a) sv_w12 sv_eot ds_et ds_cmpl ec1 ec2 ds_pt;
   by usubjid;
   if a;
    %createCustomVars(adsDomain=adsl, vars=PH1SDT PH1EDT PH2SDT PH2EDT);

         PH1SDT = randdt; *randomization;

         if not missing(p2_ecstdt) then PH1EDT=p2_ecstdt-1;
         else if saffl="N" and not missing(randdt) then ph1edt=randdt;
         else if dsnext="POST-TREATMENT" and nmiss(svenwk12, DSSTDT_pt)<2 then PH1EDT=min(svenwk12, DSSTDT_pt);  *a Note message may in log due to data not available yet of ongoing post-treatment period;
         else if nmiss(trtedt,sveneot)<2 then PH1EDT=max(trtedt,sveneot); *a Note message may in log due to data not available yet of ongoing treatment period;
         else if not missing(ph1sdt) then put "WARN" "ING: Wired case for PH1EDT for usubjid=" usubjid ". May due to ongoing. Please check.";

         if not missing(p2_ecstdt) then PH2SDT=p2_ecstdt;

         if not missing(PH2SDT) then do;
             if DSSTDT_cmpl >= PH2SDT then PH2EDT=DSSTDT_cmpl;
             else if .z <DSSTDT_cmpl < PH2SDT then do;
                 put "WARN" "ING: Treatment completion date in DS is before PH2SDT for usubjid=" usubjid ". Need to log into DIL.";
             END;
             else if nmiss(trtedt,sveneot)<2 then PH2EDT=max(trtedt,sveneot); *a Note message may in log due to data not available yet of ongoing treatment period;
             else if not missing(ph2sdt) then put "WARN" "ING: Wired case for PH2EDT for usubjid=" usubjid ". May due to ongoing. Please check.";
         END;
RUN;


*<*****************************************************************************;
*< Late ADS processing;
*<*****************************************************************************;

%late_ads_processing(adsDat = &adsDomain.)

%endprog()

