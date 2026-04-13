%MACRO m_create_qs_promis(

) / DES = 'add PROMIS related ANALYSIS variables and paramcd e.g Total ';
/*******************************************************************************
 * Bayer AG
 * Macro rely on: pure SAS
 *******************************************************************************
 * Purpose          : Create PROMIS related ANALYSIS variables and paramcd e.g Total
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * Parameters       : N/A
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
 * Author(s)        : gmrnq (Susie Zhang) / date: 06NOV2023
 * Reference prog   :
 *******************************************************************************
 * Change History   :
 ******************************************************************************/

/*******************************************************************************
 * Examples         :
   %m_create_qs_promis();
 ******************************************************************************/



data adqs_tot;
    set &adsDomain._derive (where=(QSCAT in ('PROMIS SLEEP DISTURBANCE SHORT FORM 8B V1.0')));
    if not missing(aval) then naval = aval;
RUN;

* Get the first assessment for each visit only;
proc sort data=adqs_tot;
    by usubjid qscat avisitn adt atm qstestcd;
RUN;

data adqs_ft(keep=usubjid qscat avisitn adt atm);
    set adqs_tot;
    by usubjid qscat avisitn adt atm qstestcd;
    if first.avisitn;
RUN;

data _promis_info;
    merge adqs_tot adqs_ft(in=b);
    by usubjid qscat avisitn adt atm;
    if b;
RUN;


* Select all avisits and qstestcd;
proc sql;
    create table _promis_avisitn as
    select distinct avisitn, studyid, adsname, domain, qstestcd
    from adqs_tot;
QUIT;

* Select all subjects;
proc sql;
    create table _promis_usubjid as
    select distinct usubjid, trt01an, trt01pn, trtsdt
    from ads.adsl
    where fasfl="Y";
QUIT;

proc sql;
    create table _promis_cat as
    select distinct qscat, qsscat, parcat1, parcat2, qsevlint, qsevintx
    from _promis_info;
QUIT;

* Create a dummy data for all subjects with all avisits;
proc sql;
    create table _promis_dummy as
    select *
    from _promis_usubjid, _promis_cat, _promis_avisitn
    order by studyid, domain, adsname, usubjid, qscat, qsscat, parcat1, parcat2, avisitn, qstestcd;
QUIT;

* Separate dummy data before and after week 12;
data _promis_dummy_wk12 _promis_dummy_aft12;
    set _promis_dummy;
    if avisitn<=120 then output _promis_dummy_wk12;
    else output _promis_dummy_aft12;
RUN;

* Get info of at least one record for the week;
proc sort data=_promis_info(keep=studyid usubjid avisitn) out=_one_visitn nodupkey;
    by studyid usubjid avisitn;
RUN;

* Only select dummy data after week 12 for avisitn with at least one record;
proc sort data=_one_visitn; by studyid usubjid avisitn; run;
proc sort data=_promis_dummy_aft12; by studyid usubjid avisitn; run;

data _promis_dummy_post12;
    merge _promis_dummy_aft12(in=a) _one_visitn(in=b);
    by studyid usubjid avisitn;
    if a and b;
RUN;

* Combine dummy data before week 12 for every subject and after week 12 with at least one record;
data _promis_dummy2;
    set _promis_dummy_wk12
        _promis_dummy_post12;
RUN;

proc sort data=_promis_dummy2;
    by studyid domain adsname usubjid qscat qsscat parcat1 parcat2 avisitn qstestcd;
RUN;

* Check whether the subject skips questions;
proc sort data=_promis_info;
    by studyid domain adsname usubjid qscat qsscat parcat1 parcat2 avisitn qstestcd;
RUN;

data _promis_tot;
    merge _promis_info(drop=trtsdt qsevlint qsevintx) _promis_dummy2(in=b);
    by studyid domain adsname usubjid qscat qsscat parcat1 parcat2 avisitn qstestcd;
    if b;
RUN;


* PROMIS raw score;
proc sql;
    create table promis_tt as
    select *, sum(naval) as total from _promis_tot
    where QSCAT='PROMIS SLEEP DISTURBANCE SHORT FORM 8B V1.0'
    group by usubjid, qscat, avisitn, adt;
QUIT;

* Convert to T-Score according to SAP table 6-1: Sleep Disturbance 8b - Conversion Table;
data promis;
    set promis_tt;
    attrib tscore format=4.1;
    select(total);

    when(8)  tscore  = 28.9;
    when(9)  tscore  = 33.1;
    when(10) tscore  = 35.9;
    when(11) tscore  = 38.0;
    when(12) tscore  = 39.8;
    when(13) tscore  = 41.4;
    when(14) tscore  = 42.9;
    when(15) tscore  = 44.2;
    when(16) tscore  = 45.5;
    when(17) tscore  = 46.7;
    when(18) tscore  = 47.9;
    when(19) tscore  = 49.0;
    when(20) tscore  = 50.1;
    when(21) tscore  = 51.2;
    when(22) tscore  = 52.2;
    when(23) tscore  = 53.3;
    when(24) tscore  = 54.3;
    when(25) tscore  = 55.3;
    when(26) tscore  = 56.3;
    when(27) tscore  = 57.3;
    when(28) tscore  = 58.3;
    when(29) tscore  = 59.4;
    when(30) tscore  = 60.4;
    when(31) tscore  = 61.5;
    when(32) tscore  = 62.6;
    when(33) tscore  = 63.7;
    when(34) tscore  = 64.9;
    when(35) tscore  = 66.1;
    when(36) tscore  = 67.5;
    when(37) tscore  = 69.0;
    when(38) tscore  = 70.8;
    when(39) tscore  = 73.0;
    when(40) tscore  = 76.5;
    otherwise tscore=.;
    end;
RUN;

* PSDSB998: Total Score raw of PROMIS sleep disturbance short form 8B V1.0;
data promis_total_raw(drop=naval total tscore);
    set promis;
    by usubjid qscat avisitn adt;
    AVAL=total;
    AVALC=" ";
    QSTESTCD='PSDSB998';
    QSORRES=" ";
    QSTEST=" ";
    PARAMTYP="DERIVED";
    if last.avisitn;
RUN;

* PSDSB999: Total T-Score of PROMIS sleep disturbance short form 8B V1.0;
data promis_total_tscore(drop=naval total tscore);
    set promis;
    by usubjid qscat avisitn adt;
    AVAL=tscore;
    AVALC=" ";
    QSTESTCD='PSDSB999';
    QSORRES=" ";
    QSTEST=" ";
    PARAMTYP="DERIVED";
    if last.avisitn;
RUN;


data &adsDomain.;
    set &adsDomain. promis_total_raw promis_total_tscore;
RUN;


/*******************************************************************************
 * End of macro
 ******************************************************************************/

%MEND m_create_qs_promis;