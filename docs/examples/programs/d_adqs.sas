/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = d_adqs);
/*
 * Purpose          : Derivation of ADQS
 * Programming Spec :
 * Validation Level : 2 - Verification by Double Programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gmrnq (Susie Zhang) / date: 25OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/d_adqs.sas (gmrnq (Susie Zhang) / date: 12OCT2023)
 ******************************************************************************/
/* Changed by       : gmrnq (Susie Zhang) / date: 07DEC2023
 * Reason           : Update History of Menopause
 ******************************************************************************/
/* Changed by       : gmrnq (Susie Zhang) / date: 13DEC2023
 * Reason           : Update AVISITN remapping rules
 ******************************************************************************/


%let adsDomain = ADQS;

*<******************************************************************************;
*< Early ADS processing;
*<******************************************************************************;
%early_ads_processing(
    adsDat = &adsDomain.
  , adsLib = WORK
)

*<******************************************************************************;
*< Check collected QS data;
*<******************************************************************************;

*< Keep ADQS data except HFDD and Sleep scale;
* Because HFDD and Sleep scale are included in another dataset;
data adqs_qs;
    set &adsDomain.;
    if qscat not in ('TWICE DAILY HOT FLASH DIARY V2.0', 'SLEEPINESS SCALE V1.0');

    length AVALC  $200.;

    if not missing (qsorres) then do;
        *For the value only containing digits, not including any character letter or colon;
        *e.g. "35";
        if anyfirst(qsorres) = 0 and index (qsorres , ":") = 0 and not missing(qsstresn) then do;
            AVAL =qsstresn;
            AVALC= strip(put(aval, best.));
        END;

        *For the value only containing character letter;
        *e.g. "Breast cancer";
        else if index (qsorres , ":") = 0 then do;
            AVAL=.;
            AVALC = strip(qsorres);
        END;

        *For the value with digits and character letters;
        *e.g. "0: I make decisions about as well as ever.";
        *e.g. "1: 1a I sleep somewhat more than usual.";
        else if index (qsorres , ":") = 2 then do;

            * Note: if qsstresn is different from numeric value of qsorres, AVAL take numeric value of qsorres;
            if qsstresn ne . then do;
                if qsorres ne '' then _qsorres_n=input(scan(qsorres, 1,':'),best.);
                if qsorres ne '' and qsstresn ^=_qsorres_n then AVAL=_qsorres_n;
                else AVAL=qsstresn;
            end;

            if find(qsorres, ': 0')>0 then do;
                AVALC = strip(substr(qsorres, (index (qsorres, ": 0") +3)));
            end;
            else if find(qsorres, ': 1a')>0 then do;
                AVALC = strip(substr(qsorres, (index (qsorres, ": 1a") +3)));
            end;
            else if find(qsorres, ': 1b')>0 then do;
                AVALC = strip(substr(qsorres, (index (qsorres, ": 1b") +3)));
            end;
            else if find(qsorres, ': 2a')>0 then do;
                AVALC = strip(substr(qsorres, (index (qsorres, ": 2a") +3)));
            end;
            else if find(qsorres, ': 2b')>0 then do;
                AVALC = strip(substr(qsorres, (index (qsorres, ": 2b") +3)));
            end;
            else if find(qsorres, ': 3a')>0 then do;
                AVALC = strip(substr(qsorres, (index (qsorres, ": 3a") +3)));
            end;
            else if find(qsorres, ': 3b')>0 then do;
                AVALC = strip(substr(qsorres, (index (qsorres, ": 3b") +3)));
            end;
            else do;
                AVALC = strip(substr(qsorres, (index (qsorres, ":") +1)));
            end;
        END;

        *For all others;
        else do;
            AVALC = strip(qsorres);
        END;

        *For the value with '-' only;
        *e.g. "-" ;
        if strip(qsorres)='-' then call missing(AVAL, AVALC);

        *For the value with carriage returns, replace carriage returns with space;
        *e.g. "[0D][0A]5 years after...";
        if find(qsorres, '0D0A'x)>0 then do;
            AVALC= strip(TRANWRD(AVALC,'0D0A'x," "));
        END;
    end;

    drop _qsorres_n;
run;

* Bring in TRTSDT from adsl;
proc sql noprint;
    create table &adsDomain. as
           select a.*, b.trtsdt, b.randdt
           from adqs_qs as a
           left join ads.adsl as b
           on a.usubjid=b.usubjid;
QUIT;

* Populate QSDY if QSDY is missing but QSDTC is not missing;
data &adsDomain.;
    set &adsDomain.;
    _qsdy=qsdy;
    if qsdy=. and not missing(qsdtc) then do;
        if find(qsdtc,"T")>0 then qsdy=input(scan(qsdtc,1,"T"), yymmdd10.)-randdt+(input(scan(qsdtc,1,"T"), yymmdd10.)>=randdt);
        else qsdy=input(qsdtc, yymmdd10.)-randdt+(input(qsdtc, yymmdd10.)>=randdt);
    END;
    else qsdy=_qsdy;
    drop _qsdy randdt;
RUN;


*<******************************************************************************;
*< Remap Avisitn;
*<******************************************************************************;

*< Map visitnum to avisitn;
%m_visit2avisit(indat=&adsDomain.,outdat=&adsDomain., EOT=WEEK26);

*< Set initial priority;
data &adsDomain.;
    set &adsDomain.;

    * The smaller of _v_priority, the more important as the first record will be selected for the scheduled visit;
         if visitnum eq 700000 then _v_priority=142;                  * Low priority;
    else if visitnum eq 900000 then _v_priority=132;
    else if visitnum eq 600000 then _v_priority=122;
    else if visitnum eq .      then _v_priority=112;
    else _v_priority=2;                                               * High priority;

    * For other categories except History of Menopause: set avisitn to missing if qsdy>1 and visit=BASELINE;
    if qscat ^= "HISTORY OF MENOPAUSE HORMONE THERAPY BAYER  V1.0" then do;
        if visitnum=5 and qsdy>1 then avisitn=.;
    END;

    * For visitnum=EOT, set avisitn=600010 for Columbia Since Last Visit category and temporary set to missing for other categories;
    if visitnum eq 600000 and qsdy ne . then do;
        if qscat="COLUMBIA-SUICIDE SEVERITY RATING SCALE (BAYER) SINCE LAST VISIT (ECOA)" then avisitn=600010;
        else avisitn=.;
    END;

    * For visitnum=UNS, temporary set to missing for other categories;
    if visitnum eq 900000 and qsdy ne . then avisitn=.;

RUN;

proc sort data=&adsDomain.;
    by studyid usubjid qscat qsscat avisitn adt atm;
RUN;

data &adsDomain._fst(keep=studyid usubjid qscat qsscat avisitn adt atm);
    set &adsDomain.(where=(avisitn>=5));
    by studyid usubjid qscat qsscat avisitn adt atm;
    if first.avisitn;
RUN;

data &adsDomain.;
    merge &adsDomain.(in=a) &adsDomain._fst(in=b);
    by studyid usubjid qscat qsscat avisitn adt atm;
    if a;
    if b then _v_priority=_v_priority-1;
run;

*< Calculate the weekday;
data &adsDomain.;
    set &adsDomain.;
    * As per Stats, week 1 is day 2 to 8;
    if 2 <= qsdy <= 8 then do;
        _qsdy_weekday=qsdy - 1;
    END;
    else do;
        if qsdy gt 0 and mod(qsdy,7) eq 0 then do;
            _qsdy_weekday=7;
        END;
        else if qsdy gt 0 and mod(qsdy,7) ne 0 then do;
            _qsdy_weekday=qsdy - floor(qsdy/7)*7;
        END;
        else do;
            _qsdy_weekday=.;
        END;
    END;

RUN;


*< For BDI: remap the closest record to day 1 as 5-BASELINE;
data &adsDomain._bdi &adsDomain._nbdi ;
    set &adsDomain.;
    if find(qscat,'BECK DEPRESSION INVENTORY')>0 then output &adsDomain._bdi;
    else output &adsDomain._nbdi;
RUN;

proc sort data=&adsDomain._bdi out=&adsDomain._bdi_base;
    by studyid usubjid qscat qsscat adt;
    where (avisitn=. or .<avisitn <=5) and (.< adt <= trtsdt or trtsdt=.) and aval ne . and qsstat ^="NOT DONE";
RUN;

*** Check all baseline records should be before EC individual dose ECSTDTC day and time;
data ec_date(keep=studyid usubjid ecst_adt ecst_atm);
    set sp.ec;
    if ECCAT="STUDY DRUG EXPOSURE, INDIVIDUAL DOSE" and visitnum=5;
    ecst_adt=input(scan(ecstdtc,1, "T"),yymmdd10.);
    ecst_atm=input(scan(ecstdtc,2, "T"),time5.);
    format ecst_adt date9. ecst_atm time5.;
RUN;

proc sort data=ec_date; by studyid usubjid ecst_adt ecst_atm; run;

data &adsDomain._bdi_base2;
    merge &adsDomain._bdi_base(in=a) ec_date;
    by studyid usubjid;
    if a;
    if ecst_adt ^=. and (adt>ecst_adt) or (adt=ecst_adt and atm>=ecst_atm) then delete;
RUN;

*** Get the last record as baseline and combine them back to data;
data &adsDomain._bdi_ablfl(keep=studyid usubjid qscat qsscat avisitn adt);
    set &adsDomain._bdi_base2;
    by studyid usubjid qscat qsscat adt atm;
    if last.qsscat;
RUN;

proc sort data=&adsDomain._bdi_ablfl;
    by studyid usubjid qscat qsscat avisitn adt;
RUN;

proc sort data=&adsDomain._bdi;
    by studyid usubjid qscat qsscat avisitn adt;
RUN;

data &adsDomain._bdi2;
    merge &adsDomain._bdi(in=a) &adsDomain._bdi_ablfl(in=b);
    by studyid usubjid qscat qsscat avisitn adt;
    if a;

    * Set avisitn to 5-Baseline if the closest record to day 1;
    if b then do;
        avisitn=5;
        _v_priority=9;
    END;
RUN;

data &adsDomain.;
    set &adsDomain._bdi2
        &adsDomain._nbdi;
RUN;



*< Remap rules - Firstly, check the record in completion dates;
* Remap avisitn to completion days when visitnum is missing;
data &adsDomain.;
    set &adsDomain.;
    * Select records with VISITNUM=., EOT, UNS and Follow-up (MENQOL, PROMIS only for PD subjects);
    if qsdy ne . and qsstat^="NOT DONE" and
    (visitnum in (., 600000, 900000) or
        (visitnum = 700000 and qsdy<=85 and qscat in ('PROMIS SLEEP DISTURBANCE SHORT FORM 8B V1.0','MENOPAUSE-SPECIFIC QUALITY-OF-LIFE QUESTIONNAIRE (MENQOL)')))
    then do;
        * For categories in PROMIS SD SF 8b, EQ-5D-5L, PGI-S;
        if qscat in ('PROMIS SLEEP DISTURBANCE SHORT FORM 8B V1.0', 'EQ-5D-5L')
           or (qscat ='PATIENT GLOBAL IMPRESSION VASOMOTOR SYMPTOMS V1.0' and qstestcd in ('PGVB101', 'PGVB102', 'PGVB103')) then do;
                    if  8 <= qsdy <=  9 then do; AVISITN=10;  _com_day="Y"; end; * Week 1 for completion day 8-9;
               else if 15 <= qsdy <= 16 then do; AVISITN=20;  _com_day="Y"; end; * Week 2 for completion day 15-16;
               else if 22 <= qsdy <= 23 then do; AVISITN=30;  _com_day="Y"; end; * Week 3 for completion day 22-23;
               else if 29 <= qsdy <= 30 then do; AVISITN=40;  _com_day="Y"; end; * Week 4 for completion day 29-30;
               else if 55 <= qsdy <= 57 then do; AVISITN=80;  _com_day="Y"; end; * Week 8 for completion day 55-57;
               else if 83 <= qsdy <= 85 then do; AVISITN=120; _com_day="Y"; end; * Week 12 for completion day 83-85;
           END;

           * For the categories in MENQOL, ISI, BDI-II, PGI-C;
          if find(qscat, 'MENOPAUSE-SPECIFIC QUALITY-OF-LIFE QUESTIONNAIRE')>0
              or qscat ='ISI'
              or find(qscat, 'BECK DEPRESSION INVENTORY')>0
              or (qscat ='PATIENT GLOBAL IMPRESSION VASOMOTOR SYMPTOMS V1.0' and qstestcd in ('PGVB104', 'PGVB105', 'PGVB106')) then do;
                     if 29 <= qsdy <= 30 then do; AVISITN=40;  _com_day="Y"; end;  * Week 4 for completion day 29-30;
                else if 55 <= qsdy <= 57 then do; AVISITN=80;  _com_day="Y"; end;  * Week 8 for completion day 55-57;
                else if 83 <= qsdy <= 85 then do; AVISITN=120; _com_day="Y"; end;  * Week 12 for completion day 83-85;
          END;

       if _com_day="Y" then do;
                if visitnum=700000 then _v_priority=14;
           else if visitnum=900000 then _v_priority=13;
           else if visitnum=600000 then _v_priority=12;
           else if visitnum=.      then _v_priority=11;
       END;

    END;
RUN;

* Keep the one with highest priority, otherwise set to avisitn=.;
data &adsDomain.;
    set &adsDomain.;
    length _qsscat $200.;
    if qstestcd in ('PGVB101', 'PGVB102', 'PGVB103') then _qsscat="PGI-S";
    else if qstestcd in ('PGVB104', 'PGVB105', 'PGVB106') then _qsscat="PGI-C";
    else _qsscat="";

    %createCustomVars(adsDomain=adqs, vars= DTYPE);
    dtype='';
RUN;

proc sort data=&adsDomain. out=&adsDomain._com;
    where _com_day="Y";
    by studyid usubjid qscat _qsscat avisitn _v_priority qsdy;
RUN;

data &adsDomain._com_fst(keep=studyid usubjid qscat _qsscat avisitn _v_priority qsdy);
    set &adsDomain._com;
    by studyid usubjid qscat _qsscat avisitn _v_priority qsdy;
    if first.avisitn;
RUN;

proc sort data=&adsDomain.;
    by studyid usubjid qscat _qsscat avisitn _v_priority qsdy;
RUN;

data &adsDomain.;
    merge &adsDomain.(in=a) &adsDomain._com_fst(in=b);
    by studyid usubjid qscat _qsscat avisitn _v_priority qsdy;
    if a;
    if b then _priority_fl='Y';
RUN;

data &adsDomain.;
    set &adsDomain.;
    if _com_day="Y" and _priority_fl^='Y' then do;
        if visitnum in (., 600000, 900000) then avisitn=.;
        else if visitnum = 700000 then avisitn=700000;
    END;
RUN;


*<  Remap rules - Secondly, apply remapping rules;
* Temporary assign to the previous week for week 4 onwards;
data &adsDomain.;
    set &adsDomain.;
    * Select records with VISITNUM=., EOT, UNS and Follow-up (MENQOL, PROMIS only for PD subjects);
    if qsdy ne . and qsstat^="NOT DONE" and
    (visitnum in (., 600000, 900000) or
        (visitnum = 700000 and qsdy<=85 and qscat in ('PROMIS SLEEP DISTURBANCE SHORT FORM 8B V1.0','MENOPAUSE-SPECIFIC QUALITY-OF-LIFE QUESTIONNAIRE (MENQOL)')))
    then do;
        * For categories in PROMIS SD SF 8b, EQ-5D-5L, PGI-S;
        if qscat in ('PROMIS SLEEP DISTURBANCE SHORT FORM 8B V1.0', 'EQ-5D-5L')
           or (qscat ='PATIENT GLOBAL IMPRESSION VASOMOTOR SYMPTOMS V1.0' and qstestcd in ('PGVB101', 'PGVB102', 'PGVB103')) then do;
                 if  2 <= qsdy <=  7 and _qsdy_weekday >= 5 then do; AVISITN=10; _temp_day="D"; end; * Remap week 1 on 5th day or later to Week 1;
            else if 10 <= qsdy <= 14 and _qsdy_weekday >= 5 then do; AVISITN=20; _temp_day="D"; end; * Remap week 2 on 5th day or later to Week 2;
            else if 17 <= qsdy <= 21 and _qsdy_weekday >= 5 then do; AVISITN=30; _temp_day="D"; end; * Remap week 3 on 5th day or later to Week 3;
            else if  24 <= qsdy <= 28  then do; AVISITN= 30; _temp_day="Y"; end;   * Temporary assign to the calendar week 3;
            else if  43 <= qsdy <= 54  then do; AVISITN= 70; _temp_day="Y"; end;   * Temporary assign to the calendar week 7;
            else if  71 <= qsdy <= 82  then do; AVISITN=110; _temp_day="Y"; end;   * Temporary assign to the calendar week 11;
            else if  99 <= qsdy <= 112 then do; AVISITN=150; _temp_day="Y"; end;   * Temporary assign to the calendar week 15;
            else if 169 <= qsdy <= 182 then do; AVISITN=250; _temp_day="Y"; end;   * Temporary assign to the calendar week 25;
        END;

        * For the categories in MENQOL, ISI, BDI-II, PGI-C;
        if find(qscat, 'MENOPAUSE-SPECIFIC QUALITY-OF-LIFE QUESTIONNAIRE')>0
           or qscat ='ISI'
           or find(qscat, 'BECK DEPRESSION INVENTORY')>0
           or (qscat ='PATIENT GLOBAL IMPRESSION VASOMOTOR SYMPTOMS V1.0' and qstestcd in ('PGVB104', 'PGVB105', 'PGVB106')) then do;
                 if  15 <= qsdy <= 28  then do; AVISITN= 30; _temp_day="Y"; end;   * Temporary assign to the calendar week 3;
            else if  43 <= qsdy <= 54  then do; AVISITN= 70; _temp_day="Y"; end;   * Temporary assign to the calendar week 7;
            else if  71 <= qsdy <= 82  then do; AVISITN=110; _temp_day="Y"; end;   * Temporary assign to the calendar week 11;
            else if  99 <= qsdy <= 112 then do; AVISITN=150; _temp_day="Y"; end;   * Temporary assign to the calendar week 15;
            else if 169 <= qsdy <= 182 then do; AVISITN=250; _temp_day="Y"; end;   * Temporary assign to the calendar week 25;
        END;

        if _temp_day in ("D", "Y") then do;
                if visitnum=700000 then _v_priority=24;
           else if visitnum=900000 then _v_priority=23;
           else if visitnum=600000 then _v_priority=22;
           else if visitnum=.      then _v_priority=21;
        END;

    END;
RUN;

* Check the last assessment closest to the completion days;
proc sort data=&adsDomain.;
    by studyid usubjid qscat avisitn qsdy;
RUN;

data &adsDomain._lst(keep=studyid usubjid qscat avisitn qsdy);
    set &adsDomain.;
    by studyid usubjid qscat avisitn qsdy;
    if last.avisitn;
    if avisitn ^=.;
RUN;

data &adsDomain.;
    merge &adsDomain.(in=a)
          &adsDomain._lst(in=b);
    by studyid usubjid qscat avisitn qsdy;
    if a;
    if b then _last_to_com="Y";
RUN;

data &adsDomain.;
    set &adsDomain.;
    _avisitn=avisitn;
    if _last_to_com^="Y" and _com_day^="Y" and _temp_day="Y" and _avisitn^=. then avisitn=.;
    else avisitn=_avisitn;
    drop _avisitn;
RUN;

* Apply two weeks mapping rules;
%let newcond=%str(%(visitnum in %(., 600000, 900000%) or %(visitnum=700000 and qsdy<=85 and qscat in %('PROMIS SLEEP DISTURBANCE SHORT FORM 8B V1.0','MENOPAUSE-SPECIFIC QUALITY-OF-LIFE QUESTIONNAIRE (MENQOL)'%)%)%));

* Remap week 3 to week 4 only if Week 4 assessment is missing;
%m_remap_qs_twoweeks(cond=&newcond., week_schedule=4);

* Remap week 7 to week 8 only if Week 8 assessment is missing;
%m_remap_qs_twoweeks(cond=&newcond., week_schedule=8);

* Remap week 11 to week 12 only if Week 12 assessment is missing;
%m_remap_qs_twoweeks(cond=&newcond., week_schedule=12);

* Remap week 15 to week 16 only if Week 16 assessment is missing;
%m_remap_qs_twoweeks(cond=%str(visitnum in (., 600000, 900000)), week_schedule=16);

* Remap week 25 to week 26 only if Week 26 assessment is missing;
%m_remap_qs_twoweeks(cond=%str(visitnum in (., 600000, 900000)), week_schedule=26);



*<#yellow ******************************************************************************;
*<#yellow Use follow-up records for scheduled visits for prematurely discontinued subjects;
*<#yellow ******************************************************************************;

* Select subjects who are discontinued on and before week 12;
proc sql noprint;
    create table subj_dis as
           select distinct(usubjid), studyid, astdt as _dis_date, astdy as _dis_ady
           from ads.adds
           where ice01fl="Y";
QUIT;

proc sort data=&adsDomain.; by studyid usubjid; run;
proc sort data=subj_dis; by studyid usubjid; run;

data &adsDomain._dis;
    merge &adsDomain.(in=a) subj_dis(in=b);
    by studyid usubjid;
    if a;
    if b then _dis_fl="Y";
RUN;


* Select subjects who have visitnum=700000 record from source data;
data fup_ori(keep=studyid usubjid qscat qstestcd qsdy);
    set &adsDomain.;
    if visitnum=700000;
RUN;

proc sort data=fup_ori;
    by studyid usubjid qscat qstestcd qsdy;
RUN;

data subj_fup(keep=studyid usubjid qscat);
    set fup_ori;
    by studyid usubjid qscat qstestcd qsdy;
    if first.qscat;
RUN;

proc sort data=&adsDomain._dis; by studyid usubjid qscat; run;
proc sort data=subj_fup; by studyid usubjid qscat; run;

data &adsDomain._dis_fl;
    merge &adsDomain._dis(in=a) subj_fup(in=b);
    by studyid usubjid qscat;
    if a;
    if b then _fup_fl="Y";
RUN;

*<#yellow Separate the dataset into three groups;
data &adsDomain._fl &adsDomain._nfl &adsDomain._oth;
    set &adsDomain._dis_fl;

    * For MENQOL and PROMIS;
    if find(qscat, 'MENOPAUSE-SPECIFIC QUALITY-OF-LIFE QUESTIONNAIRE')>0 or qscat in ('PROMIS SLEEP DISTURBANCE SHORT FORM 8B V1.0') then do;
        if _fup_fl="Y" then output &adsDomain._fl;
        else output &adsDomain._nfl;
    end;
    * For EQ-5D-5L, BDI, ISI, PGI;
    else if find(qscat, 'BECK DEPRESSION INVENTORY')>0
      or qscat in ('ISI', 'PATIENT GLOBAL IMPRESSION VASOMOTOR SYMPTOMS V1.0', 'EQ-5D-5L') then do;
        if _fup_fl^="Y" then output &adsDomain._nfl;
        else output &adsDomain._oth;
      end;
    * For other categories;
    else output &adsDomain._oth;
RUN;


*<#yellow For subject premature discontinued with collected follow-up record exists;
* Check priority of each avisitn;
proc sort data=&adsDomain._fl; by studyid usubjid qscat qsscat avisitn _v_priority adt atm; run;

data &adsDomain._fl_fst(keep=studyid usubjid qscat qsscat avisitn adt atm);
    set &adsDomain._fl;
    by studyid usubjid qscat qsscat avisitn _v_priority adt atm;
    if first.avisitn;
    if avisitn ^=.;
RUN;

proc sort data=&adsDomain._fl_fst; by studyid usubjid qscat qsscat avisitn adt atm; run;
proc sort data=&adsDomain._fl; by studyid usubjid qscat qsscat avisitn adt atm; run;

data &adsDomain._fl2;
    merge &adsDomain._fl(in=a) &adsDomain._fl_fst(in=b);
    by studyid usubjid qscat qsscat avisitn adt atm;
    if a;
    if b then _priority_fl="Y";
run;

data &adsDomain._fl3;
    set &adsDomain._fl2;
    if visitnum=700000 and _priority_fl^="Y" then avisitn=700000;

    * Duplicate the transformed follow-up visit be dummy scheduled week with dtype="COPY";
    if _dis_fl="Y" and visitnum=700000 and _priority_fl="Y" and avisitn in (10, 20, 30, 40, 80, 120) and ady>_dis_ady>. and ady<=85
    and (find(qscat, 'MENOPAUSE-SPECIFIC QUALITY-OF-LIFE QUESTIONNAIRE')>0 or qscat ='PROMIS SLEEP DISTURBANCE SHORT FORM 8B V1.0')
    then do;
        dtype="COPY";
        output;
        dtype="";
        avisitn=700000;
        output;
    END;
    else output;
RUN;



*<#yellow For subject premature discontinued without collected follow-up record exists;
data &adsDomain._nfl2;
    set &adsDomain._nfl;
    * For the categories in MENQOL, ISI, BDI-II, PGI-C and for categories in PROMIS SD SF 8b, EQ-5D-5L, PGI-S;
    if find(qscat, 'MENOPAUSE-SPECIFIC QUALITY-OF-LIFE QUESTIONNAIRE')>0
      or find(qscat, 'BECK DEPRESSION INVENTORY')>0
      or qscat in ('ISI', 'PATIENT GLOBAL IMPRESSION VASOMOTOR SYMPTOMS V1.0','PROMIS SLEEP DISTURBANCE SHORT FORM 8B V1.0', 'EQ-5D-5L');

    * Check the subjects with schedule visits that are (after disc+2);
    if _dis_fl="Y" and ady>_dis_ady+2;
    _abs=abs(qsdy-(_dis_ady+28));
RUN;

proc sort data=&adsDomain._nfl2;
    by studyid usubjid qscat _qsscat _abs qsdy;
RUN;

data &adsDomain._nfl2_ft(keep=studyid usubjid qscat _qsscat qsdy);
    set &adsDomain._nfl2;
    by studyid usubjid qscat _qsscat _abs qsdy;
    if first._qsscat;
RUN;

proc sort data=&adsDomain._nfl;
    by studyid usubjid qscat _qsscat qsdy ;
RUN;

proc sort data=&adsDomain._nfl2_ft;
    by studyid usubjid qscat _qsscat qsdy ;
RUN;

data &adsDomain._nfl3;
    merge &adsDomain._nfl(in=a)
          &adsDomain._nfl2_ft(in=b);
    by studyid usubjid qscat _qsscat qsdy ;
    if a;
    if b then _dup_from_sch="Y";
RUN;


* For those categories that needs to be remapped, flag the record of avisitn^=. that is selected as the closest one to (disc day + 28));
data &adsDomain._nfl_cat;
    set &adsDomain._nfl3;
    * For the categories in MENQOL, ISI, BDI-II, PGI-C and for categories in PROMIS SD SF 8b, EQ-5D-5L, PGI-S;
    if find(qscat, 'MENOPAUSE-SPECIFIC QUALITY-OF-LIFE QUESTIONNAIRE')>0
      or find(qscat, 'BECK DEPRESSION INVENTORY')>0
      or qscat in ('ISI', 'PATIENT GLOBAL IMPRESSION VASOMOTOR SYMPTOMS V1.0','PROMIS SLEEP DISTURBANCE SHORT FORM 8B V1.0', 'EQ-5D-5L') then do;
          if _dup_from_sch="Y" and _dup_to_wk4 ^="Y" and avisitn^=. then _av="Y";
      END;
run;

proc sort data=&adsDomain._nfl_cat out=&adsDomain._nfl_cat_s(keep=studyid usubjid qscat _av) nodupkey;
    where _av="Y";
    by studyid usubjid qscat _av;
RUN;

proc sort data=&adsDomain._nfl3;
    by studyid usubjid qscat;
RUN;

data &adsDomain._nfl_cat2;
    merge &adsDomain._nfl3(in=a)
          &adsDomain._nfl_cat_s;
    by studyid usubjid qscat;
    if a;
RUN;

data &adsDomain._nfl4;
    set &adsDomain._nfl_cat2;

    * For categories in PROMIS SD SF 8b, EQ-5D-5L, PGI-S;
    if qscat in ('PROMIS SLEEP DISTURBANCE SHORT FORM 8B V1.0', 'EQ-5D-5L')
       or (qscat ='PATIENT GLOBAL IMPRESSION VASOMOTOR SYMPTOMS V1.0' and qstestcd in ('PGVB101', 'PGVB102', 'PGVB103')) then do;

          * For those subject with the record of avisitn^=. that is selected as the closest one to (disc day + 28));
          if _av="Y" then do;
              output;
              * Duplicate the closest one to (disc day + 28) to be follow-up visit;
              if _dup_from_sch="Y" and _dup_to_wk4 ^="Y" and avisitn^=. then do;
                  dtype="COPY";
                  avisitn=700000;
                  output;
              END;
          END;
          else do;
              * For those subject with the record of avisitn=. that is selected as the closest one to (disc day + 28));
              * Since it is not mapped to schedule visit, no need to be duplicated. Just remap it to follow-up visit;
              if _dup_from_sch="Y" and _dup_to_wk4 ^="Y" and avisitn=. then avisitn=700000;
              output;
          END;
    END;

    * For the categories in MENQOL, ISI, BDI-II, PGI-C;
    else if find(qscat, 'MENOPAUSE-SPECIFIC QUALITY-OF-LIFE QUESTIONNAIRE')>0
       or qscat ='ISI'
       or find(qscat, 'BECK DEPRESSION INVENTORY')>0
       or (qscat ='PATIENT GLOBAL IMPRESSION VASOMOTOR SYMPTOMS V1.0' and qstestcd in ('PGVB104', 'PGVB105', 'PGVB106')) then do;

        * For those subject with the record of avisitn^=. that is selected as the closest one to (disc day + 28));
        if _av="Y" then do;
            * Remap to be follow-up visit in case avisitn=. with _av="Y";
            * e.g. day 14 is mapped to week 2(avisitn^=.) for PGI-S but day 14 will not be mapped to schedule weeks(avisitn=.) for PGI-C;
            * So regarding PGI-C, day 14 will be remapped to follow-up records;
            if _dup_from_sch="Y" and _dup_to_wk4 ^="Y" and avisitn=. and 12<=qsdy<=14 then avisitn=700000;
            output;

            * Duplicate the closest one to (disc day + 28) to be follow-up visit;
            if _dup_from_sch="Y" and _dup_to_wk4 ^="Y" and avisitn^=. and (qsdy<12 or qsdy>14) then do;
                dtype="COPY";
                avisitn=700000;
                output;
            END;

        END;
        else do;
            * For those subject with the record of avisitn=. that is selected as the closest one to (disc day + 28));
            * Since it is not mapped to schedule visit, no need to be duplicated. Just remap it to follow-up visit;
            if _dup_from_sch="Y" and _dup_to_wk4 ^="Y" and avisitn=. then avisitn=700000;
            output;
        END;

    END;

    * For other categories expect the above;
    else output;
RUN;



*<#yellow Combine three groups;
data &adsDomain.;
    set &adsDomain._fl3
        &adsDomain._nfl4
        &adsDomain._oth;
run;



*<******************************************************************************;
*< Set analysis flag for the scheduled visits;
*<******************************************************************************;

*<#pink Separate data into different datasets;
proc sort data=&adsDomain.;
    by studyid usubjid qscat qsscat avisitn _v_priority adt atm qsevlint qsevintx;
RUN;

data &adsDomain._csb &adsDomain._csl &adsDomain._ncsb &adsDomain._pgi &adsDomain._ncsp;
    set &adsDomain.;
    if find(qscat,"COLUMBIA-SUICIDE") and find(qscat,"BASELINE") then output &adsDomain._csb;
    else if qscat="COLUMBIA-SUICIDE SEVERITY RATING SCALE (BAYER) SINCE LAST VISIT (ECOA)" then output &adsDomain._csl;
    else if avisitn<=5 and visitnum ^=600000 then output &adsDomain._ncsb;
    else if qscat="PATIENT GLOBAL IMPRESSION VASOMOTOR SYMPTOMS V1.0" then output &adsDomain._pgi;
    else output &adsDomain._ncsp;
RUN;

*<#pink For C-SSRS BASELINES/SCREENING;
data &adsDomain._csb_out(keep=studyid usubjid qscat avisitn _v_priority adt atm);
    set &adsDomain._csb;
    if find(qstestcd,"CSSB401");
RUN;

data &adsDomain._csb_no(keep=studyid usubjid qscat avisitn _v_priority adt atm);
    set &adsDomain._csb;
    if find(qstestcd,"CSSB401") and qsorres in ("INCOMPLETE", "NOT DONE", "-");
RUN;

proc sort data=&adsDomain._csb_out; by studyid usubjid qscat avisitn _v_priority adt atm ; RUN;
proc sort data=&adsDomain._csb_no nodupkey; by studyid usubjid qscat avisitn _v_priority adt atm ; RUN;

data &adsDomain._csb_val(keep=studyid usubjid qscat avisitn _v_priority adt atm );
    merge &adsDomain._csb_out(in=a) &adsDomain._csb_no(in=b);
    by studyid usubjid qscat avisitn _v_priority adt atm ;
    if a and not b;
RUN;

data &adsDomain._csb_val_lst;
    set &adsDomain._csb_val;
    by studyid usubjid qscat avisitn _v_priority adt atm;
    if last.avisitn;
RUN;

proc sort data=&adsDomain._csb; by studyid usubjid qscat avisitn _v_priority adt atm; RUN;

data &adsDomain._csb2;
    merge &adsDomain._csb(in=a) &adsDomain._csb_val_lst(in=b);
    by studyid usubjid qscat avisitn _v_priority adt atm;
    if a;
    if b and qsstat^="NOT DONE" then do;
        anl04fl="Y";
        avisitn=5;
    end;
    else anl04fl="";
RUN;

data &adsDomain._csb2_v(keep=studyid usubjid qscat avisitn adt atm rename=(avisitn=avisitn_b));
    set &adsDomain._csb2(where=(anl04fl="Y"));
RUN;

proc sort data=&adsDomain._csb2_v nodupkey; by studyid usubjid qscat adt atm; RUN;
proc sort data=&adsDomain._csb2; by studyid usubjid qscat adt atm; RUN;

data &adsDomain._csb3;
    merge &adsDomain._csb2(in=a) &adsDomain._csb2_v(in=b);
    by studyid usubjid qscat adt atm;
    if a;
    _avisitn=avisitn;
    if b then avisitn=avisitn_b;
    else avisitn=_avisitn;
    drop _avisitn avisitn_b;
RUN;

*<#pink For C-SSRS Since Last Visit;
data &adsDomain._csl_out(keep=studyid usubjid qscat avisitn _v_priority adt atm);
    set &adsDomain._csl;
    if find(qstestcd,"CSSB201");
RUN;

data &adsDomain._csl_no(keep=studyid usubjid qscat avisitn _v_priority adt atm);
    set &adsDomain._csl;
    if find(qstestcd,"CSSB201") and qsorres in ("INCOMPLETE", "NOT DONE", "-");
RUN;

proc sort data=&adsDomain._csl_out; by studyid usubjid qscat avisitn _v_priority adt atm ; RUN;
proc sort data=&adsDomain._csl_no nodupkey; by studyid usubjid qscat avisitn _v_priority adt atm ; RUN;

data &adsDomain._csl_val(keep=studyid usubjid qscat avisitn _v_priority adt atm );
    merge &adsDomain._csl_out(in=a) &adsDomain._csl_no(in=b);
    by studyid usubjid qscat avisitn _v_priority adt atm ;
    if a and not b;
RUN;

data data &adsDomain._csl_val_fst;
    set &adsDomain._csl_val;
    by studyid usubjid qscat avisitn _v_priority adt atm;
    if first.avisitn;
    if avisitn ^=.;
RUN;

proc sort data=&adsDomain._csl; by studyid usubjid qscat avisitn _v_priority adt atm; RUN;

data &adsDomain._csl2;
    merge &adsDomain._csl(in=a) &adsDomain._csl_val_fst(in=b);
    by studyid usubjid qscat avisitn _v_priority adt atm;
    if a;
    if b and qsstat^="NOT DONE" then anl04fl="Y";
    else anl04fl="";
RUN;


*<#pink For other data regarding screening and baseline;
proc sort data=&adsDomain._ncsb;
    by studyid usubjid qscat adt atm qsevlint qsevintx;
RUN;

* History of Menopause can have valid records with qsdy >1;
data &adsDomain._ncsb_h &adsDomain._ncsb_nh;
    set &adsDomain._ncsb;
    if find(qscat, "HISTORY OF MENOPAUSE HORMONE THERAPY BAYER") then output &adsDomain._ncsb_h;
    else output &adsDomain._ncsb_nh;
RUN;

* Get the last record of History of Menopause;
data &adsDomain._ncsb_h_lst(keep=studyid usubjid qscat adt atm);
    set &adsDomain._ncsb_h;
    by studyid usubjid qscat adt atm qsevlint qsevintx;
    if last.qscat;
RUN;

* Get the last record of non History of Menopause;
data &adsDomain._ncsb_nh2;
    set &adsDomain._ncsb_nh;
    if .<adt<=trtsdt or trtsdt=.;
    if not (avisitn=0 and ady>1);
RUN;

data &adsDomain._ncsb_nh_lst(keep=studyid usubjid qscat adt atm);
    set &adsDomain._ncsb_nh2;
    by studyid usubjid qscat adt atm qsevlint qsevintx;
    if last.qscat;
RUN;

* Combine the last record;
data &adsDomain._ncsb_lst;
    set &adsDomain._ncsb_h_lst
        &adsDomain._ncsb_nh_lst;
RUN;

proc sort data=&adsDomain._ncsb_lst;
    by studyid usubjid qscat adt atm ;
RUN;

proc sort data=&adsDomain._ncsb;
    by studyid usubjid qscat adt atm qsevlint qsevintx;
RUN;

data &adsDomain._ncsb1;
    merge &adsDomain._ncsb(in=a) &adsDomain._ncsb_lst(in=b);
    by studyid usubjid qscat adt atm;
    if a;
    if b then _tofl="Y";
RUN;

data &adsDomain._ncsb2;
    set &adsDomain._ncsb1;
    if find(qscat,"HISTORY OF MENOPAUSE HORMONE THERAPY BAYER")>0 then do;
        if _tofl="Y" and qsorres^="NOT CHECKED" then anl04fl="Y";
    END;
    else do;
        if _tofl="Y" and qsstat^="NOT DONE" then do;
            anl04fl="Y";
            avisitn=5;
        END;
        else anl04fl="";
    END;
    drop _tofl;
RUN;

data &adsDomain._ncsb2_v(keep=studyid usubjid qscat avisitn adt atm rename=(avisitn=avisitn_b));
    set &adsDomain._ncsb2(where=(anl04fl="Y" and avisitn=5));
RUN;

proc sort data=&adsDomain._ncsb2_v nodupkey; by studyid usubjid qscat adt atm; RUN;
proc sort data=&adsDomain._ncsb2; by studyid usubjid qscat adt atm; RUN;

data &adsDomain._ncsb3;
    merge &adsDomain._ncsb2(in=a) &adsDomain._ncsb2_v(in=b);
    by studyid usubjid qscat adt atm;
    if a;
    _avisitn=avisitn;
    if b then avisitn=avisitn_b;
    else avisitn=_avisitn;
    drop _avisitn avisitn_b;
RUN;


*<#pink For other data regarding post baseline for PGI;
* PGI-S and PGI-C to be seperate forms;
* To use both data in case PGI-S and PGI-C have different dates;
proc sort data=&adsDomain._pgi;
    by studyid usubjid qscat _qsscat avisitn _v_priority adt atm;
RUN;

data &adsDomain._pgi_fst(keep=studyid usubjid qscat _qsscat avisitn adt atm);
    set &adsDomain._pgi;
    by studyid usubjid qscat _qsscat avisitn _v_priority adt atm;
    if first.avisitn;
    if avisitn ^=.;
RUN;

proc sort data=&adsDomain._pgi_fst; by studyid usubjid qscat _qsscat avisitn adt atm; run;
proc sort data=&adsDomain._pgi; by studyid usubjid qscat _qsscat avisitn adt atm; run;

data &adsDomain._pgi2(drop=_qsscat);
    merge &adsDomain._pgi(in=a) &adsDomain._pgi_fst(in=b);
    by studyid usubjid qscat _qsscat avisitn adt atm;
    if a;
    if b and qsstat^="NOT DONE" then anl04fl="Y";
    else anl04fl="";
    if not b and visitnum in (600000, 900000) then avisitn=.;
    if anl04fl^="Y" and visitnum in (., 600000, 900000) then avisitn=.;
RUN;


*<#pink For other data regarding post baseline expect PGI;

data &adsDomain._ncsp_fst(keep=studyid usubjid qscat qsscat avisitn adt atm);
    set &adsDomain._ncsp;
    by studyid usubjid qscat qsscat avisitn _v_priority adt atm;
    if first.avisitn;
    if avisitn ^=.;
RUN;

proc sort data=&adsDomain._ncsp_fst; by studyid usubjid qscat qsscat avisitn adt atm; run;
proc sort data=&adsDomain._ncsp; by studyid usubjid qscat qsscat avisitn adt atm; run;

data &adsDomain._ncsp2;
    merge &adsDomain._ncsp(in=a) &adsDomain._ncsp_fst(in=b);
    by studyid usubjid qscat qsscat avisitn adt atm;
    if a;
    if b and qsstat^="NOT DONE" then do;
        if dtype="LOCF" or (dtype="COPY" and visitnum=700000 and avisitn in (10, 20,30, 40, 80, 120)) then anl04fl="";
        else anl04fl="Y";
    end;
    else anl04fl="";
    if not b and visitnum in (., 600000, 900000) then avisitn=.;
    if anl04fl^="Y" and dtype ^="LOCF" and visitnum in (., 600000, 900000) then avisitn=.;

    * set analysis flag to null for CLO records;
    if qscat='CLOSE LIVER OBSERVATION CASE REVIEW (V1.0)' then anl04fl="";
RUN;


*<#pink Combine the above datasets;
data &adsDomain. ;
    set &adsDomain._csb3
        &adsDomain._csl2
        &adsDomain._ncsb3
        &adsDomain._pgi2
        &adsDomain._ncsp2;

    * For not remapped "Unscheduled" visits, set anl04fl to missing;
    if visitnum=900000 and avisitn=900000 then anl04fl="";
RUN;



*<******************************************************************************;
*< Reset analysis flag for subjects who premature discontinued on or before week 12;
*<******************************************************************************;
proc sort data=fup_ori out=fup_ori_one(keep=studyid usubjid qscat) nodupkey;
    by studyid usubjid qscat;
run;

proc sort data=fup_ori_one; by studyid usubjid qscat; run;
proc sort data=&adsDomain.; by studyid usubjid qscat; run;

data &adsDomain.;
    merge &adsDomain.(in=a) fup_ori_one(in=b);
    by studyid usubjid qscat;
    if a;
    if b then _fup_check="Y";
RUN;

data &adsDomain.;
    set &adsDomain.;
    * For the categories in MENQOL, ISI, BDI-II, PGI-C and for categories in PROMIS SD SF 8b, EQ-5D-5L, PGI-S;
    if find(qscat, 'MENOPAUSE-SPECIFIC QUALITY-OF-LIFE QUESTIONNAIRE')>0
      or find(qscat, 'BECK DEPRESSION INVENTORY')>0
      or qscat in ('ISI', 'PATIENT GLOBAL IMPRESSION VASOMOTOR SYMPTOMS V1.0','PROMIS SLEEP DISTURBANCE SHORT FORM 8B V1.0', 'EQ-5D-5L')
    then do;
        if dtype="LOCF" then anl04fl="";
        else do;
            * For subject premature discontinued with collected follow-up record exists;
            if _dis_fl="Y" and _fup_check="Y" then do;
                * Set anl04fl to missing, for dummy schedule record that is duplicated from follow-up record;
                if dtype ="COPY" and avisitn^=700000 then anl04fl="";
                * Set anl04fl to missing, for other records that is after (discontinued day + 2);
                else if dtype^="COPY" and avisitn^=700000 and qsdy>_dis_ady+2 then anl04fl="";
                else if avisitn=. then anl04fl="";
                else anl04fl="Y";
            end;

            * For subject premature discontinued without collected follow-up record exists;
            if _dis_fl="Y" and _fup_check^="Y" then do;
                * Set anl04fl to YES, for the created follow up visit that is duplicated from the closest record to (discontinued day + 28);
                if dtype ="COPY" and avisitn=700000 then anl04fl="Y";
                * Set anl04fl to missing, for other records that is after (discontinued day + 2);
                else if dtype^="COPY" and avisitn^=700000 and qsdy>_dis_ady+2 then anl04fl="";
                else if avisitn=. then anl04fl="";
                else anl04fl="Y";
            end;
        END;
    END;

    * For other categories expect history of MENOPAUSE;
    if find(qscat,"HISTORY OF MENOPAUSE HORMONE THERAPY BAYER")=0 then do;
        if avisitn=0 and ady>1 then anl04fl="";
    END;

RUN;



*<******************************************************************************;
*< Get the collected QS data;
*<******************************************************************************;

proc sort data=&adsDomain. out=&adsDomain._ori;
    by studyid usubjid qscat qsscat avisitn qsdtc qstestcd ;
RUN;

*<******************************************************************************;
*< Derive Total Score
*<******************************************************************************;

* Select scheduled week records for derived paramcd: Screening, Baseline Visit, Week 1,2,3,4,8,12,16,26, Follow-up;
data &adsDomain._derive;
    set &adsDomain.;
    * For BDI: select Baseline(created earlier from last Screening), Week 4,8,12,16,26, Follow-up;
    if find(qscat, 'BECK DEPRESSION INVENTORY')>0 then do;
        if avisitn in (5,40,80,120,160,260,700000) then output;
    END;
    * For ISI and MENQOL: select Baseline Visit, 4,8,12,16,26, Follow-up;
    if find(qscat, 'MENOPAUSE-SPECIFIC QUALITY-OF-LIFE QUESTIONNAIRE')>0 or find(qscat, 'ISI')>0 then do;
        if avisitn in (5,40,80,120,160,260,700000) then output;
    END;
    * For PROMIS: select Baseline Visit, Week 1,2,3,4,8,12,16,26, Follow-up;
    if qscat in ('PROMIS SLEEP DISTURBANCE SHORT FORM 8B V1.0') then do;
        if avisitn in (5,10,20,30,40,80,120,160,260,700000) then output;
    END;
run;


* Derive total BDI;
%m_create_qs_bdi;

* Derive total ISI;
%m_create_qs_isi;

* Derive total PROMIS;
%m_create_qs_promis;

* Derive total MENQOL;
%m_create_qs_menqol;



*<******************************************************************************;
*< Add baseline BASE, CHG, PCHG for derived paramcd;
*<******************************************************************************;

* Split data for derived records and non- records;
DATA &adsDomain._dvd  &adsDomain._nd;
    set &adsDomain.;

    *PARAMCD;
    %createCustomVars(adsDomain=adqs, vars= PARAMCD );
    PARAMCD = QSTESTCD;

    *Reset qsseq to missing for all derived paramcd;
    if paramtyp="DERIVED" then do;
        qsseq= .;
        output &adsDomain._dvd;
    end;
    else output &adsDomain._nd;
RUN;

* Add baseline flag for derived records;
proc sort data=&adsDomain._dvd out=&adsDomain._dvd_base;
    by studyid usubjid parcat1 paramcd avisitn adt;
    where paramtyp='DERIVED' and avisitn <=5 and (.< adt <= trtsdt or trtsdt=.) and aval ne .;
RUN;

data &adsDomain._dvd_ablfl(keep=studyid usubjid parcat1 paramcd avisitn adt);
    set &adsDomain._dvd_base;
    by studyid usubjid parcat1 paramcd avisitn adt atm;
    if last.paramcd;
RUN;

proc sort data=&adsDomain._dvd;
    by studyid usubjid parcat1 paramcd avisitn adt;
RUN;

data &adsDomain._dvd2;
    merge &adsDomain._dvd(in=a) &adsDomain._dvd_ablfl(in=b);
    by studyid usubjid parcat1 paramcd avisitn adt;
    if a;
    %createCustomVars(adsDomain=adqs, vars=ABLFL);
    _avisitn=avisitn;
    * Set avisitn to 5-Baseline if the actual visit is Screening but to be used as BASELINE;
    if b then do;
        ablfl='Y';
        avisitn=5;
    END;
    * Set avisitn to null if visitnum=baseline but ady>trtsdt;
    if not b then do;
        if _avisitn=5 and ady>1 then do;
            avisitn=.;
            put "WARN" "ING: Subject has visit=baseline but ADY >1 - USUBJID=" USUBJID", ADY=" ADY;
        end;
        else avisitn=_avisitn;
    END;
    drop=_avisitn;
RUN;

data &adsDomain._dvd_base(keep=studyid usubjid parcat1 paramcd dvd_adt_base base);
    set &adsDomain._dvd2;
    if ablfl='Y';
    base=aval;
    rename adt=dvd_adt_base ;
RUN;

proc sort data=&adsDomain._dvd_base; by studyid usubjid parcat1 paramcd; RUN;
proc sort data=&adsDomain._dvd2; by studyid usubjid parcat1 paramcd; RUN;

data &adsDomain._dvd3;
    merge &adsDomain._dvd2(in=a) &adsDomain._dvd_base(in=b);
    by studyid usubjid parcat1 paramcd;
    if a;
    %createCustomVars(adsDomain=adqs, vars = chg pchg);
    if aval ne . and base ne . then do;
        chg = aval - base;
        if base^=0 then pchg=((aval-base)/base)*100;
    END;
RUN;

data &adsDomain. ;
    set &adsDomain._dvd3
        &adsDomain._nd;
RUN;


*<******************************************************************************;
*< Add baseline BASE, CHG, PCHG for EQVAS SCORE EQ-5D-5L total score from SDTM;
*<******************************************************************************;

data &adsDomain._eq(drop=ablfl base chg pchg) &adsDomain._neq;
    set &adsDomain.;
    if qscat='EQ-5D-5L' and qstestcd='EQ5D0206' then output &adsDomain._eq;
    else output &adsDomain._neq;
RUN;

* Add baseline BASE, ABLFL for EQVAS SCORE;
proc sort data=&adsDomain._eq out=&adsDomain._eq_base;
    by studyid usubjid parcat1 paramcd avisitn adt;
    where avisitn <=5 and (.< adt <= trtsdt or trtsdt=.) and aval ne .;
RUN;

data &adsDomain._eq_ablfl(keep=studyid usubjid parcat1 paramcd avisitn adt);
    set &adsDomain._eq_base;
    by studyid usubjid parcat1 paramcd avisitn adt atm;
    if last.paramcd;
RUN;

proc sort data=&adsDomain._eq;
    by studyid usubjid parcat1 paramcd avisitn adt;
RUN;

data &adsDomain._eq2;
    merge &adsDomain._eq(in=a) &adsDomain._eq_ablfl(in=b);
    by studyid usubjid parcat1 paramcd avisitn adt;
    if a;
    %createCustomVars(adsDomain=adqs, vars=ABLFL);
    * Set avisitn to 5-Baseline if the actual visit is Screening but to be used as BASELINE;
    if b then do;
        ablfl='Y';
        avisitn=5;
    END;
RUN;

data &adsDomain._eq_base(keep=studyid usubjid parcat1 paramcd eq_adt_base base);
    set &adsDomain._eq2;
    if ablfl='Y';
    base=aval;
    rename adt=eq_adt_base ;
RUN;

proc sort data=&adsDomain._eq_base; by studyid usubjid parcat1 paramcd; RUN;
proc sort data=&adsDomain._eq2; by studyid usubjid parcat1 paramcd; RUN;

data &adsDomain._eq3;
    merge &adsDomain._eq2(in=a) &adsDomain._eq_base(in=b);
    by studyid usubjid parcat1 paramcd;
    if a;
RUN;

data &adsDomain._eq4;
    set &adsDomain._eq3;
    if ablfl ^='Y' and adt<eq_adt_base then base=.;

    %createCustomVars(adsDomain=adqs, vars = chg pchg);
    if aval ne . and base ne . then do;
        chg = aval - base;
        if base ^=0 then pchg=((aval-base)/base)*100;
    END;
RUN;

proc sort data= &adsDomain._eq4;
    by studyid usubjid qscat qstestcd avisitn adt;
RUN;

data &adsDomain.;
    set &adsDomain._eq4
        &adsDomain._neq;
RUN;


*<******************************************************************************;
*< Add ATPTN;
*<******************************************************************************;

data &adsDomain. ;
    set &adsDomain.;
    %createCustomVars(adsDomain=adqs, vars=ATPTN);
    if not missing(qsevintx) then do;
        select(qsevintx);
            when ('TODAY')                            atptn=99999930.01;
            when ('SINCE LAST VISIT')                 atptn=99999930.02;
            when ('SINCE TAKING STUDY MEDICATION')    atptn=99999930.03;
            when ('LIFETIME')                         atptn=99999930.04;
            otherwise                                 atptn=.;
        END;
    END;
    else if not missing(qsevlint) then do;
        select(qsevlint);
            when ('-P24M')                            atptn=-99999993.24;
            when ('-P6M')                             atptn=-99999993.06;
            when ('-P2W')                             atptn=-99999992.02;
            when ('-P1W')                             atptn=-99999992.01;
            when ('-P7D')                             atptn=-99999991.07;
            otherwise                                 atptn=.;
        END;
    END;
run;


*<******************************************************************************;
*< Reset ANL04FL for derived records;
*<******************************************************************************;

proc sort data=fup_ori_one; by studyid usubjid qscat; run;
proc sort data=&adsDomain.; by studyid usubjid qscat; run;

data &adsDomain.;
    merge &adsDomain.(in=a) fup_ori_one(in=b);
    by studyid usubjid qscat;
    if a;
    if b then _fup_check_dr="Y";
RUN;

data &adsDomain. ;
    set &adsDomain.;

    * For the categories in MENQOL, ISI, BDI-II, PGI-C and for categories in PROMIS SD SF 8b, EQ-5D-5L, PGI-S;
    if find(qscat, 'MENOPAUSE-SPECIFIC QUALITY-OF-LIFE QUESTIONNAIRE')>0
      or find(qscat, 'BECK DEPRESSION INVENTORY')>0
      or qscat in ('ISI', 'PATIENT GLOBAL IMPRESSION VASOMOTOR SYMPTOMS V1.0','PROMIS SLEEP DISTURBANCE SHORT FORM 8B V1.0', 'EQ-5D-5L')
    then do;
        if paramtyp="DERIVED" then do;
            * For subject premature discontinued with collected follow-up record exists;
            if _dis_fl="Y" and _fup_check_dr="Y" then do;
                * Set anl04fl to missing, for dummy schedule record that is duplicated from follow-up record;
                if dtype ="COPY" and avisitn^=700000 then anl04fl="";
                * Set anl04fl to missing, for other records that is after (discontinued day + 2);
                else if dtype^="COPY" and avisitn^=700000 and qsdy>_dis_ady+2 then anl04fl="";
                * Set anl04fl to missing, for dummy Week 4 that is duplicated from week 3;
                else if dtype="LOCF" then anl04fl="";
                * Set anl04fl to missing, for any records with missing avisitn;
                else if avisitn=. then anl04fl="";
                * Otherwise set to anl04fl to Yes;
                else anl04fl="Y";
            end;

            * For subject premature discontinued without collected follow-up record exists;
            else if _dis_fl="Y" and _fup_check_dr^="Y" then do;
                * Set anl04fl to YES, for the created follow up visit that is duplicated from the closest record to (discontinued day + 28);
                if dtype ="COPY" and avisitn=700000 then anl04fl="Y";
                * Set anl04fl to missing, for other records that is after (discontinued day + 2);
                else if dtype^="COPY" and avisitn^=700000 and qsdy>_dis_ady+2 then anl04fl="";
                * Set anl04fl to missing, for dummy Week 4 that is duplicated from week 3;
                else if dtype="LOCF" then anl04fl="";
                * Set anl04fl to missing, for any records with missing avisitn;
                else if avisitn=. then anl04fl="";
                * Otherwise set to anl04fl to Yes;
                else anl04fl="Y";
            end;

            * Set dtype to missing for derived records;
            dtype="";
        END;
    END;

    * Set anl04fl to missing if aval is missing;
    if paramtyp="DERIVED" and aval=. then anl04fl="";
RUN;


*<******************************************************************************;
*< Add AVALCAyN variable for categorized total score;
*<******************************************************************************;

data &adsDomain.;
    set &adsDomain.;
    %createCustomVars(adsDomain=adqs, vars=AVALCA1N);
    *Add AVALCA1N variable for categorized total score of BDI-II;
    if paramcd = "BDIB999"  then do ;
             if  0 le aval le 13 then avalca1n=1;
        else if 14 le aval le 19 then avalca1n=2;
        else if 20 le aval le 28 then avalca1n=3;
        else if 29 le aval le 63 then avalca1n=4;
        else avalca1n=.;
    end;

    * Add AVALCA1N variable for categorized total score of ISI;
    if paramcd = "ISIB0999" then do ;
             if  0 le aval le  7 then avalca1n=11;
        else if 8  le aval le 14 then avalca1n=12;
        else if 15 le aval le 21 then avalca1n=13;
        else if 22 le aval le 28 then avalca1n=14;
        else avalca1n=.;
    end;
run;

proc sort data= &adsDomain.; by usubjid qsseq parcat1 paramcd adt ady avisitn;
RUN;


*<******************************************************************************;
*< Add ICE and VMS variables;
*<******************************************************************************;

%m_create_qs_ice;


*<******************************************************************************;
*< Finalize ADS;
*<******************************************************************************;
* Output to ADS;
data ADS.&adsDomain.;
    set &adsDomain.;
RUN;

* Late ADS processing;
%late_ads_processing(adsDat = ADS.&adsDomain.)


%endprog()

