%MACRO m_create_qs_menqol(

) / DES = 'add MENQOL related ANALYSIS variables and paramcd e.g Total ';
/*******************************************************************************
 * Bayer AG
 * Macro rely on: pure SAS
 *******************************************************************************
 * Purpose          : Create MENQOL related ANALYSIS variables and paramcd e.g Total
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * Parameters       : N/
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
   %m_create_qs_menqol();
 ******************************************************************************/



data _adqs_tot;
    set &adsDomain._derive ;
    if find(qscat, 'MENOPAUSE-SPECIFIC QUALITY-OF-LIFE QUESTIONNAIRE')>0;
RUN;


*< Bring in treatment group from adsl;
proc sort data=ads.adsl out=_adsl(keep=usubjid trt01an trt01pn);
    where fasfl="Y";
    by usubjid;
RUN;

proc sort data=_adqs_tot;
    by usubjid qscat adt qstestcd;
RUN;

data _adqs_totnew;
    merge _adqs_tot(in=a) _adsl;
    by usubjid;
    if a;
RUN;

*< Start Imputation;
* Select MENQOL for in person visits;
* For Baseline (avisitn=5),week 1(avisitn=10),4(avisitn=40),8(avisitn=80),12(avisitn=120),16(avisitn=160),26(avisitn=260) and 30(avisitn=700000);
data _adqs_impu;
    set _adqs_totnew;
    if avisitn in (5,10,40,80,120,160,260,700000) then output _adqs_impu;
RUN;

* MENQOL QSORRES is the score value if QSTESTCD containing A, e.g. MENB101A;
* MENQOL QSORRES is the YES/NO value if QSTESTCD without A, e.g. MENB101;
data _menqol_yesno
     _menqol_score(keep=studyid domain adsname usubjid qscat parcat1 parcat2 adt atm ady qstestcd avisitn qsorres qsstresc aval avalc qsevlint qsevintx);
    set _adqs_impu;
    if index(qstestcd,"A") > 0 then output _menqol_score;
    else output _menqol_yesno;
RUN;

data _menqol_yn_a;
    set _menqol_yesno(drop=qsstresc aval avalc rename=(qsorres=_qsorres_yesno));
    qstestcd = compress(catx('',qstestcd,'A'));
RUN;

proc sort data=_menqol_yn_a; by studyid domain adsname usubjid qscat parcat1 parcat2 qstestcd avisitn adt atm ady qsevlint qsevintx; RUN;
proc sort data=_menqol_score; by studyid domain adsname usubjid qscat parcat1 parcat2 qstestcd avisitn adt atm ady qsevlint qsevintx; RUN;

* Combine yesno data with score value;
data _menqol_both;
    merge _menqol_yn_a(in=a) _menqol_score;
    by studyid domain adsname usubjid qscat parcat1 parcat2 qstestcd avisitn adt atm ady qsevlint qsevintx;
    if a then _yesno=1;
run;

* Convert aval to score as per table 6-2 in the SAP;
data _menqol_both;
    set _menqol_both;
    if find(upcase(_qsorres_yesno), "NO") then do;
        qsorres=_qsorres_yesno;
        _aval_sc=1;
    end;

    if not missing (aval) then _aval_sc=aval+2;
RUN;

* Use the first assessment for multiple assessments in the same week;
proc sort data=_menqol_both;
    by usubjid qscat avisitn adt atm ady qstestcd;
RUN;

data _menqol_ft(keep=usubjid qscat avisitn adt atm ady);
    set _menqol_both;
    by usubjid qscat avisitn adt atm ady qstestcd;
    if first.avisitn;
RUN;

data _menqol_first;
    merge _menqol_both _menqol_ft(in=b);
    by usubjid qscat avisitn adt atm ady;
    if b;
RUN;


*< Output MENQOL 29 items;
data menqol_item(drop=_qstestcd);
    set _menqol_first;
    _qstestcd=qstestcd;

    if not missing(_aval_sc) then aval=_aval_sc;
        else aval=.;
    avalc="";
    if substr(qstestcd,8)='A' then qstestcd=substr(_qstestcd,1,4)||"8"||substr(_qstestcd,6,2);
        else qstestcd="";
    qsorres="";
    qstest="";
    paramtyp="DERIVED";
    if not missing (qstestcd);
RUN;


*< Preparation for imputation;
* Check domains;
data _menqol_info(drop=num);
    set _menqol_first;
    num = input(substr(scan(qstestcd,1,"A"),6), best.);
    * Domain 1: Vasomotor 1-3;
    if 1 le num  le 3 then _cat=1;
    * Domain 2: Psychosocial 4-10;
    if 4 le num le 10 then _cat=2;
    * Domain 3: Physical 11-26;
    if 11 le num le 26 then _cat=3;
    * Domain 4: Sexual 27-29;
    if 27 le num le 29 then _cat=4;
RUN;


* Select all avisits and qstestcd;
proc sql;
    create table _adqs_avisitn as
    select distinct avisitn, studyid, adsname, domain, qstestcd, _cat
    from _menqol_info;
QUIT;


* Select all subjects;
proc sql;
    create table _adqs_usubjid as
    select distinct usubjid, trt01an, trt01pn,trtsdt
    from ads.adsl
    where fasfl="Y";
QUIT;

proc sql;
    create table _adqs_cat as
    select distinct qscat, qsscat, parcat1, parcat2, qsevlint, qsevintx
    from _adqs_totnew;
QUIT;

* Create a dummy data for all subjects with all avisits;
proc sql;
    create table _adqs_dummy as
    select *
    from _adqs_usubjid, _adqs_cat, _adqs_avisitn
    order by studyid, domain, adsname, usubjid, qscat, qsscat, parcat1, parcat2, avisitn, qstestcd, _cat, trt01an, trt01pn, trtsdt;
QUIT;

* Separate dummy data before and after week 12;
data _adqs_dummy_wk12 _adqs_dummy_aft12;
    set _adqs_dummy;
    if avisitn<=120 then output _adqs_dummy_wk12;
    else output _adqs_dummy_aft12;
RUN;

* Get info of at least one record for the week;
proc sort data=_menqol_info(keep=studyid usubjid avisitn _cat) out=_one_visitn nodupkey;
    by studyid usubjid avisitn _cat;
RUN;

* Only select dummy data after week 12 for avisitn with at least one record;
proc sort data=_one_visitn; by studyid usubjid avisitn _cat; run;
proc sort data=_adqs_dummy_aft12; by studyid usubjid avisitn _cat; run;

data _adqs_dummy_post12;
    merge _adqs_dummy_aft12(in=a) _one_visitn(in=b);
    by studyid usubjid avisitn _cat;
    if a and b;
RUN;

* Combine dummy data before week 12 for every subject and after week 12 with at least one record;
data _adqs_dummy2;
    set _adqs_dummy_wk12
        _adqs_dummy_post12;
RUN;

proc sort data=_adqs_dummy2;
    by studyid domain adsname usubjid qscat qsscat parcat1 parcat2 avisitn qstestcd _cat trt01an trt01pn trtsdt;
RUN;

* Check whether the subject skips questions;
proc sort data=_menqol_info;
    by studyid domain adsname usubjid qscat qsscat parcat1 parcat2 avisitn qstestcd _cat trt01an trt01pn trtsdt;
RUN;

data _menqol_check;
    merge _menqol_info(in=a drop=qsevlint qsevintx ) _adqs_dummy2;
    by studyid domain adsname usubjid qscat qsscat parcat1 parcat2 avisitn qstestcd _cat trt01an trt01pn trtsdt;
    if a then _qsfl="Y";
    else _qsfl="N";
RUN;

*<Impute 1: Impute missing item score when the participant skipped questions;
* Check eligible participant for imputation;
proc sql;
    create table _m1_count as
    select usubjid, avisitn, adt, _cat, count(usubjid) as _scount from _menqol_info
    where usubjid in (select usubjid from _menqol_check where _qsfl='Y')
    group by usubjid, avisitn, adt, _cat
    order by usubjid, avisitn, adt, _cat;
QUIT;


* Check the participants has responded to more than one half of the domain items;
* i.e. at least two items in the vasomotor domain, two items in the sexual domain;
* four items in the psychosocial domain and nine items in the physical domain;
data _m1_subj_impute;
    set _m1_count;
    if _cat=1 and _scount>=2 then _morefl="Y";
    else if _cat=2 and _scount>=4 then _morefl="Y";
    else if _cat=3 and _scount>=9 then _morefl="Y";
    else if _cat=4 and _scount>=2 then _morefl="Y";
    else _morefl="N";
RUN;

proc sort data=_menqol_check; by usubjid avisitn _cat; RUN;
proc sort data=_m1_subj_impute; by usubjid avisitn _cat; RUN;

data _m1_fl1;
    merge _menqol_check(in=a) _m1_subj_impute(keep=usubjid avisitn _cat _morefl);
    by usubjid avisitn _cat;
    if a;
    if missing(_morefl) then _morefl="N";
RUN;

* Check whether half of the participants must have responded to this qstestcd and avisitn;
* As per Stats, use trt01pn since we need FAS;
proc sql;
    create table _m1_counthalf1 as
           select trt01pn, count(distinct usubjid) as _n_total
           from ads.adsl
           where fasfl="Y"
           group by trt01pn;
QUIT;

proc sql;
    create table _m1_counthalf2 as
           select qstestcd, avisitn, trt01pn, n(_aval_sc) as _n_value
           from _m1_fl1
           where _qsfl="Y"
           group by qstestcd, avisitn, trt01pn;
QUIT;

* Create flag for half of the participants;
proc sort data=_m1_fl1; by trt01pn; run;
proc sort data=_m1_counthalf1; by trt01pn; run;
data _m1_fl1_tt;
    merge _m1_fl1(in=a) _m1_counthalf1;
    by trt01pn;
    if a;
RUN;

proc sort data=_m1_fl1_tt; by qstestcd avisitn trt01pn; run;
data _m1_fl1_ff;
    merge _m1_fl1_tt(in=a) _m1_counthalf2;
    by qstestcd avisitn trt01pn;
    if a;
RUN;

data _m1_fl2;
    set _m1_fl1_ff;
    if nmiss(_n_value, _n_total)=0 and _n_value ge _n_total/2 then _halffl="Y";
    else _halffl="N";
RUN;


* Impute missing item score at baseline;
proc sql;
    create table _m1_base as
           select *, round(mean(_aval_sc)) as _c_mean
           from _m1_fl2
           where avisitn = 5
           group by avisitn, qstestcd;
QUIT;

data _m1_base;
    set _m1_base;
    if _qsfl="N" and _morefl="Y" and _halffl="Y" and missing(_aval_sc) and not missing(_c_mean) then do;
        _aval_sc=_c_mean;
        _impute1=1;
    end;
RUN;

* Impute missing item score at post-randomization;
proc sql;
    create table _m1_post as
           select *, round(mean(_aval_sc)) as _c_mean
           from _m1_fl2
           where avisitn > 5
           group by avisitn, qstestcd, trt01pn;
QUIT;

data _m1_post;
    set _m1_post;
    if _qsfl="N" and _morefl="Y" and _halffl="Y" and missing(_aval_sc) and not missing(_c_mean) then do;
        _aval_sc=_c_mean;
        _impute1=1;
    end;
RUN;

* Combine base and post data;
data _m1_final;
    set _m1_base _m1_post;
RUN;


*<Impute 2: Impute missing item score when the participant answered "yes" but did not indicate "how bothered";
data _m2_todo;
    set _m1_final;
    if find(upcase(_qsorres_yesno), "YES")>0 and missing(qsorres) then _toimpu2="Y";
    else _toimpu2="N";
RUN;

proc sql;
    select count(usubjid) into: n_yesmiss
    from _m2_todo
    where _toimpu2="Y";
QUIT;

%if &n_yesmiss ^= 0 %then %do;
    * For the subject answered 'yes' but did not indicated 'how bothered';
    * Impute it by calculating the mean of her 'bothered' scores for all her 'yes' answers within that domain;
    proc sql;
        create table _m2_yes as
               select usubjid, avisitn, _cat, round(mean(_aval_sc)) as _yes_dm_mean
               from _m2_todo
               where find(upcase(_qsorres_yesno), "YES")>0
               group by usubjid, avisitn, _cat
               order by usubjid, avisitn, _cat;
    QUIT;

    proc sort data=_m2_todo; by usubjid avisitn _cat; run;

    data _m2_todo_1;
        merge _m2_todo _m2_yes;
        by usubjid avisitn _cat;
    RUN;

    data _m2_fyes1 (drop=_yes_dm_mean);
        set _m2_todo_1;
        if _toimpu2="Y" and _morefl="Y" then do;
            _aval_sc=_yes_dm_mean;
            _impute2=1;
        end;
    RUN;

    * If she answered 'no' to all other domain items, impute it from the mean of all other subjects who responded 'yes';
    proc sql;
        create table _m2_yes_1 as
               select usubjid, avisitn, _cat, count(usubjid) as _n_yes
               from _m2_todo
               where find(upcase(_qsorres_yesno), "YES")>0
               group by usubjid, avisitn, _cat
               order by usubjid, avisitn, _cat;
    QUIT;

    proc sql;
        create table _m2_yes_2 as
               select usubjid, avisitn, _cat, count(usubjid) as _n_all
               from _m2_todo
               group by usubjid, avisitn, _cat
               order by usubjid, avisitn, _cat;
    QUIT;

    data _m2_yes_allno(keep=usubjid avisitn _cat _allnofl);
        merge _m2_yes_1(in=a) _m2_yes_2;
        by usubjid avisitn _cat;
        if nmiss(_n_yes, _n_all)=0 and _n_yes=1 and _n_all ge 2 then do;
            _allnofl="Y";
            output;
        end;
    RUN;

    proc sort data=_m2_yes_allno; by usubjid avisitn _cat; run;
    proc sort data=_m2_fyes1; by usubjid avisitn _cat; run;

    data _m2_todo_2;
        merge _m2_fyes1(in=a) _m2_yes_allno;
        by usubjid avisitn _cat;
        if a;
    RUN;

    * Impute the value at baseline;
    proc sql;
        create table _m2_cd_base as
               select avisitn, qstestcd, round(mean(_aval_sc)) as _item_mean_b
               from _m2_todo
               where avisitn = 5
               group by avisitn, qstestcd;
    QUIT;

    proc sort data=_m2_cd_base; by avisitn qstestcd; run;
    proc sort data=_m2_todo_2; by avisitn qstestcd; run;

    data _m2_impu_b;
        merge _m2_todo_2 _m2_cd_base;
        by avisitn qstestcd;
        if find(upcase(_qsorres_yesno), "YES")>0 and _allnofl="Y" and _morefl="Y" and aval=. and _item_mean_b ^=. then do;
            _aval_sc=_item_mean_b;
            _impute3=1;
        end;
    RUN;
    proc sort data=_m2_impu_b; by usubjid qscat avisitn qstestcd; run;

    * Impute the value at post-randomization;
    proc sql;
        create table _m2_cd_post as
               select avisitn, qstestcd, trt01pn, round(mean(_aval_sc)) as _item_mean_p
               from _m2_todo
               where avisitn > 5
               group by avisitn, qstestcd, trt01pn;
    QUIT;

    proc sort data=_m2_cd_post; by avisitn qstestcd trt01pn; run;
    proc sort data=_m2_impu_b; by avisitn qstestcd trt01pn; run;

    data _m2_impu_p(drop=_item_mean_b _item_mean_p);
        merge _m2_impu_b _m2_cd_post;
        by avisitn qstestcd trt01pn;
        if  find(upcase(_qsorres_yesno), "YES")>0 and _allnofl="Y" and _morefl="Y" and _halffl="Y" and aval=. and not _item_mean_p ^=. then do;
            _aval_sc=_item_mean_p;
            _impute4=1;
        end;
    RUN;

    proc sort data=_m2_impu_p out=_m2_final;
        by qscat trt01pn avisitn usubjid qstestcd;
    run;
%END;
%else %do;
    data _m2_final;
        set _m2_todo;
        _impute2=.;
        _impute3=.;
        _impute4=.;
        _allnofl=.;
    RUN;
%END;

*< END Imputation;



*< Calculate domain score and total score;
* Calculate domain score;
proc sql;
    create table _f_dm2 as
    select usubjid, avisitn, _cat, mean(_aval_sc) as _mean_domain
    from _m2_final
    group by usubjid, avisitn, _cat
    order by usubjid, avisitn, _cat;
QUIT;

* Set the Domain Score to missing if it has missing item score in this domain;
data _f_dm1_ck(keep=usubjid avisitn _cat _scoremiss);
    set _m2_final;
    if missing(_aval_sc) and upcase(strip(qsorres))^="1: NO";
    _scoremiss="Y";
RUN;

proc sort data=_f_dm1_ck nodupkey; by usubjid avisitn _cat; RUN;

data _f_dm_mean;
    merge _f_dm2 _f_dm1_ck;
    by usubjid avisitn _cat;
    if _scoremiss="Y" then call missing(_mean_domain);
RUN;

* Calculate Total Score;
proc sql;
    create table _f_tot as
    select *, mean(_mean_domain) as _mean_total from _f_dm_mean
    group by usubjid, avisitn
    order by usubjid, avisitn, _cat;
QUIT;


* Combine with original dataset;
proc sort data=_m2_final; by usubjid avisitn _cat; run;

data _final_mean;
    merge _m2_final(in=a) _f_tot;
    by usubjid avisitn _cat;
    if a;
    drop _qsorres_yesno _yesno _qsfl _morefl _allnofl _n_value _n_total _halffl _c_mean _impute1 _toimpu2 _impute2 _impute3 _impute4 _scoremiss ;
RUN;

proc sort data=_final_mean; by usubjid avisitn adt; RUN;



*< Output MENQOL TOTAL score and domain score;
* MENQOL TOTAL score;
data menqol_total(drop=_mean_total _mean_domain _cat);
    set _final_mean;
    by usubjid avisitn adt;
    AVAL=_mean_total;
    AVALC=" ";
    QSTESTCD='MENB999';
    QSORRES=" ";
    QSTEST=" ";
    PARAMTYP="DERIVED";
    if last.avisitn;
RUN;

* MENQOL Domain 1 - Vasomotor;
data menqol_d1(drop=_mean_total _mean_domain _cat);
    set _final_mean;
    by usubjid avisitn adt;
    where _cat=1;
    AVAL=_mean_domain;
    AVALC=" ";
    QSTESTCD='MENB995';
    QSORRES=" ";
    QSTEST=" ";
    PARAMTYP="DERIVED";
    if last.avisitn;
RUN;

* MENQOL Domain 2 - Psychosocial;
data menqol_d2(drop=_mean_total _mean_domain _cat);
    set _final_mean;
    by usubjid avisitn adt;
    where _cat=2;
    AVAL=_mean_domain;
    AVALC=" ";
    QSTESTCD='MENB996';
    QSORRES=" ";
    QSTEST=" ";
    PARAMTYP="DERIVED";
    if last.avisitn;
RUN;

* MENQOL Domain 3 - Physical;
data menqol_d3(drop=_mean_total _mean_domain _cat);
    set _final_mean;
    by usubjid avisitn adt;
    where _cat=3;
    AVAL=_mean_domain;
    AVALC=" ";
    QSTESTCD='MENB997';
    QSORRES=" ";
    QSTEST=" ";
    PARAMTYP="DERIVED";
    if last.avisitn;
RUN;

* MENQOL Domain 4 - Sexual;
data menqol_d4(drop=_mean_total _mean_domain _cat);
    set _final_mean;
    by usubjid avisitn adt;
    where _cat=4;
    AVAL=_mean_domain;
    AVALC=" ";
    QSTESTCD='MENB998';
    QSORRES=" ";
    QSTEST=" ";
    PARAMTYP="DERIVED";
    if last.avisitn;
RUN;


*< Combine all datasets;
data &adsDomain.;
    set &adsDomain. menqol_item menqol_total menqol_d1 menqol_d2 menqol_d3 menqol_d4;
RUN;

proc datasets nolist nowarn;
    delete _:;
QUIT;

/*******************************************************************************
 * End of macro
 ******************************************************************************/

%MEND m_create_qs_menqol;
