/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adtte_ise_ice_km_ds);
/*
 * Purpose          : Time from randomization to permanent discontinuation of randomized treatment up to Week 12: Descriptive statistics (full analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gltlk (Rui Zeng) / date: 29NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_1_7_adtte_km_ds.sas (egavb (Reema S Pawar) / date: 06JUN2023)
 ******************************************************************************/
/* Changed by       : eqczz (Petri Pulkkinen) / date: 30NOV2023
 * Reason           : Added 2 periods to footnotes
 ******************************************************************************/
/* Changed by       : gltlk (Rui Zeng) / date: 02JAN2024
 * Reason           : update footnote
 ******************************************************************************/
/* Changed by       : evmqe (Endri Elnadav) / date: 08APR2024
 * Reason           : Change to level 1
 ******************************************************************************/

%LET mosto_param_class = &mosto_param_class_eff.;

 *T2DIS - Time to permanent discontinuation of randomized treatment (Weeks);
 *AVISITN = 121 for PHASE 1;
%load_ads_dat(
    adtte_view
  , adsDomain = adtte
  , where     = PARAMCD = 'T2DISC' and AVISITN = 121
  , adslWhere = &fas_cond
)

%load_ads_dat(adsl_view, adsDomain = adsl, where = &fas_cond)

%extend_data(
    indat       = adtte_view
  , outdat      = adtte_ext
  , var         = &extend_var_disp_eff.
  , extend_rule = &extend_rule_disp_eff.
);

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_eff.
  , extend_rule = &extend_rule_disp_eff.
);

********************** column header ******************;

DATA adsl;
     SET adsl_ext;
      IF &mosto_param_class. = 'ELIN120' THEN trtpn = 100;
      ELSE IF &mosto_param_class. = 'PLA_ELIN120' THEN trtpn = 101;
     OUTPUT;
     trtpn=9999;
     OUTPUT;
RUN;

PROC SQL NOPRINT;
    CREATE TABLE trtlabel AS
    SELECT DISTINCT trtpn, trtpn AS _trtno FORMAT=best., '_n_'||strip(put(_trtno, best.)) AS _trtvar LENGTH=10
    FROM adsl
    GROUP BY trtpn
    ORDER BY trtpn;
QUIT;RUN;

DATA trtlabel;
    SET trtlabel END=lastrec;
    LENGTH _trtord $10      __flab $200;
    _trtord='__t'||strip(put(_n_, best.));
    IF _trtno EQ 9999 THEN __flab='Total';
    ELSE __flab=strip(put(trtpn, z_trt.));
    CALL symput(_trtord, strip(put(_trtno, best.)));
    CALL symput(_trtvar, strip(__flab));
RUN;

**************** total column ************************;
DATA adtte;
    SET adtte_ext;
     IF &mosto_param_class. = 'ELIN120' THEN trtpn = 100;
     ELSE IF &mosto_param_class. = 'PLA_ELIN120' THEN trtpn = 101;
    OUTPUT;
    trtpn=9999;
    OUTPUT;
    KEEP studyid usubjid param: cnsr aval: trtpn;
RUN;

******************* KM ********************************;

ODS LISTING CLOSE;
ODS OUTPUT  quartiles = sum2 censoredsummary = sum3;
PROC LIFETEST data=adtte
              method=KM
              alpha=0.05
              outsurv=sum1 stderr
              conftype=loglog;
    TIME aval*cnsr(1);
    STRATA trtpn/notest;
    BY param:;
RUN;
ODS LISTING;

************ n, % for event, % for censored ********************;

DATA km_c;
    SET sum3;
    WHERE Stratum IN(1 2 3 );
    LENGTH _: $200;
        _1 = put(total,    5.0)||' (100.0%)';
        _2 = put(failed,   5.0)||' ('||put(100-pctcens, 5.1)||'%)';
        _3 = put(censored, 5.0)||' ('||put(pctcens,     5.1)||'%)';
    KEEP param: trtpn stratum _:;
    LABEL _1='N (%) '
          _2='Number (%) of subjects with event'
          _3='Number (%) of subjects censored';
RUN;

PROC TRANSPOSE DATA=km_c OUT=km_c PREFIX=ttt;
     BY param:;
     ID trtpn;
     VAR _:;
RUN;

************************  range ****************************;
ods escapechar="^";

DATA sum1;
    SET sum1;
    LENGTH  cen $200;
    IF _censor_ EQ 1 THEN cen="^&super_a.";
RUN;

*********************create aaa ********************************;

PROC SQL NOPRINT;
    CREATE TABLE aaa AS
    SELECT DISTINCT paramcd, trtpn, stratum, strip(put(aval, best.))||strip(cen) AS avalc LENGTH=100
    FROM sum1
    /**** range including censored values ****/
    WHERE NOT missing(_censor_)
    GROUP BY trtpn
    HAVING aval EQ MIN(aval) OR aval EQ MAX(aval);
QUIT;

***********************************************;
PROC SQL NOPRINT;
        CREATE TABLE km_r AS
        SELECT DISTINCT aaa.paramcd, aaa.trtpn, aaa.stratum,
               /**** need to compare character values for min and max to avoid case like (1081** - 14) ****/
               CASE
                    WHEN input(compress(min(avalc), "^&super_a."), best.) LE input(compress(max(avalc), "^&super_a."), best.) THEN '    ('||strip(min(avalc))||' - '||strip(max(avalc))||')'
                    WHEN input(compress(min(avalc), "^&super_a."), best.) GT input(compress(max(avalc), "^&super_a."), best.) GT .Z THEN '    ('||strip(max(avalc))||' - '||strip(min(avalc))||')'
                    ELSE ' '
               END AS _1 LENGTH=200 LABEL='Range (including censored values)',
               _2 LENGTH=200 LABEL='Range (without censored values)'

        FROM (SELECT DISTINCT paramcd, trtpn, stratum, strip(put(aval, best.))||strip(cen) AS avalc length=100
                        FROM sum1
                        /**** range including censored values ****/
                        WHERE NOT missing(_censor_)
                        GROUP BY trtpn
                        HAVING aval EQ min(aval) OR aval EQ max(aval)) AS aaa
             LEFT JOIN (SELECT DISTINCT trtpn,
                            '    ('||strip(put(min(aval), best.)||strip(cen))||' - '||strip(put(max(aval), best.)||strip(cen))||')' AS _2
                        FROM sum1
                        /**** range without censored values ****/
                        WHERE _censor_ EQ 0
                        GROUP BY trtpn) AS bbb ON aaa.trtpn=bbb.trtpn
        GROUP BY paramcd, aaa.trtpn
        ORDER BY paramcd, trtpn        ;
QUIT;

PROC TRANSPOSE DATA=km_r OUT=km_r PREFIX=ttt;
        BY paramcd;
        ID trtpn;
        VAR _1 _2;
RUN;

************ quantile ************************************;

DATA km_q;
    SET sum2 END=lastrec;
    LENGTH Weeks $200;
    IF missing(lowerlimit) THEN lowerlimit=.A;
    IF missing(upperlimit) THEN upperlimit=.A;
    IF missing(estimate) THEN estimate=.A;
    Weeks=put(estimate, 5.0)||' ['||strip(put(lowerlimit, 5.0))||';'||strip(put(upperlimit, 5.0))||']';
RUN;

PROC SORT DATA=km_q;
    BY paramcd percent;
RUN;

PROC TRANSPOSE DATA=km_q OUT=km_q (RENAME=(percent=group2)) PREFIX=ttt;
    BY paramcd percent;
    ID trtpn;
    VAR Weeks;
    format trtpn;
RUN;

************************ all together ****************************;

DATA final (DROP=paramcd);
    LENGTH ttt&__t1. ttt&__t2. ttt&__t3. _label_ _name_ paramcd $200;
    SET km_c (IN=aaa) km_q (IN=bbb) km_r (IN=ccc) ;
        IF aaa THEN DO;
            group2 = input(compress(_name_, '_'), ??best.);
            group1 = 1;
            _name_ = ' ';
        END;
        IF bbb THEN DO;
            group1=2;
            IF group2 EQ 50 THEN _label_='Median [95% CI]';
            ELSE _label_ = strip(put(group2, best.))||'th percentile [95% CI]';
            _name_ = '(Weeks)';
        END;
        IF ccc THEN DO;
            group2 = input(compress(_name_, '_'), ??best.)+100;
            group1 = 2;
            _name_ = '(Weeks)';
        END;
        LABEL _label_='#'
              _name_='#'
              group1=' '
              group2=' '

              ttt&__t1.="&&&_n_&__t1."
              ttt&__t2.="&&&_n_&__t2."
              ttt&__t3.="&&&_n_&__t3."
              ;
RUN;

%set_titles_footnotes(
    tit1 = "Table: Time from randomization to permanent discontinuation of randomized treatment up to Week 12: Descriptive statistics &fas_label."
  , ftn1 = "&foot_placebo_ezn."
  , ftn2 = "a censored observation."
  , ftn3 = "A: Value cannot be estimated due to censored data."
  , ftn4 = "Median, percentile and other 95% CIs computed using Kaplan-Meier estimates."
  , ftn5 = "CI = Confidence Interval."
  , ftn6 = 'If "Permanent discontinuation of randomized treatment" did not occur by day 84, the participant is censored at week 12.'
)

%datalist(
            data     = final
          , by       = group1 group2 _label_ _name_
          , var      = ttt&__t1. ttt&__t2. ttt&__t3.
          , order    = group1 group2
          , freeline = group1
          , optimal  = yes
          , maxlen   = 50
          , space    = 3
          , hsplit   = '#'
          , bylen    = 45
          , hv_align = LEFT
          );

%endprog;