/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_2_3_1_adtte_km_qs);
/*
 * Purpose          : Time to treatment response reduction of 50% in mean daily frequency of moderate to severe hot flashes by treatment group: Descriptive statistics
 * Programming Spec : 
 * Validation Level : 2 - Independent Programming
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 29NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21651/stat/main01/val/analysis/pgms/t_8_2_3_1_adtte_km_qs.sas (egavb (Reema S Pawar) / date: 23OCT2023)
 ******************************************************************************/
*T2DIS - Time from randomization to permament discontinuation of randomized treatment
*T2FPC - Time from randomization to first intake of prohibited concomitant medication having impact on efficacy>>: Descriptive statistics (FAS)
*T50RM - Time to treatment response reduction of 50% in mean daily frequency of moderate to severe hot flashes by treatment group: Descriptive statistics ;

%load_ads_dat(
    adtte_view
  , adsDomain = adtte
  , where     = PARAMCD = 'T50RMDF'
  , adslWhere = &fas_cond
)

%load_ads_dat(
    adsl_view
  , adsDomain = adsl
  , where     = &fas_cond
)

%extend_data(indat = adsl_view, outdat = adsl)
%extend_data(indat = adtte_view, outdat = adtte)


**************** column header, with N ****;

*double dataset to calculate total;
DATA adsl;
    ATTRIB trtpn FORMAT = z_trt.;
    SET adsl_view (RENAME=(trt01pn=trtpn));OUTPUT;
    trtpn=9999;OUTPUT;
RUN;

********* trtpn _trtno _trtvar _bign;
PROC SQL NOPRINT;
    CREATE TABLE trtlabel AS
    SELECT DISTINCT trtpn FORMAT = z_trt., trtpn AS _trtno FORMAT=best., '_n_'||strip(put(_trtno, best.)) AS _trtvar LENGTH=10,
    count(DISTINCT usubjid) AS _bign
    FROM adsl
    GROUP BY trtpn
    ORDER BY trtpn;
QUIT;
RUN;

* trtpn _trtno _trtvar _bign _trtord(macro) _flab(macro);
DATA trtlabel;
    SET trtlabel END=lastrec;
    LENGTH _trtord $10      __flab $200;
    _trtord='__t'||strip(put(_n_, best.));
    IF _trtno EQ 9999 THEN __flab='Total';
    ELSE __flab=strip(put(trtpn, z_trt.));
    CALL symput(_trtord, strip(put(_trtno, best.)));
    CALL symput(_trtvar, strip(__flab)||'#(N='||strip(put(_bign, best.))||')');
RUN;

PROC DELETE data=trtlabel;
RUN;

************ total column ****;
DATA adtte;
    ATTRIB trtpn FORMAT = z_trt.;
    SET adtte_view(RENAME=(trt01pn=trtpn));
    OUTPUT;
    trtpn=9999;
    OUTPUT;
    KEEP usubjid param: cnsr aval: trtpn;
RUN;

************ KM ****;

ODS LISTING CLOSE;
ODS OUTPUT quartiles=sum2 censoredsummary=sum3 ;
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

************ n, % for event, % for censored ****;
DATA km_c;
    SET sum3;
    WHERE Stratum IN(1 2 3 );
    LENGTH _: $200;
    _1=put(total, 5.0)||' (100.0%)';
    _2=put(failed, 5.0)||' ('||put(100-pctcens, 5.1)||'%)';
    _3=put(censored, 5.0)||' ('||put(pctcens, 5.1)||'%)';
    KEEP param: trtpn stratum _:;
    LABEL _1='N (%)'
          _2='Number (%) of subjects with event'
          _3='Number (%) of subjects censored';
RUN;

PROC TRANSPOSE DATA=km_c OUT=km_c PREFIX=ttt;
    BY param:;
    ID trtpn;
    VAR _:;
    format trtpn;
RUN;

PROC DELETE data=sum3;
RUN;


**************************** range ****;
DATA sum_cens;
    SET sum1;
    LENGTH  cen $200;
    IF _censor_ EQ 1 THEN cen="^&super_a.";
    WHERE NOT missing(_censor_);
RUN;

*****************************create aaa ********************;

PROC SQL NOPRINT;
CREATE TABLE aaa AS
SELECT DISTINCT paramcd, trtpn, stratum, strip(put(aval, best.))||strip(cen) AS avalc LENGTH=100
FROM sum_cens
/*************************** range including censored values ****/
WHERE NOT missing(_censor_)
GROUP BY trtpn
HAVING aval EQ MIN(aval) OR aval EQ MAX(aval)    ;
QUIT;


***************************************************************************************;


PROC SQL NOPRINT;
    CREATE TABLE km_r AS
    SELECT DISTINCT aaa.paramcd, aaa.trtpn, aaa.stratum,aaa._1,
           /**** need to compare character values for min and max to avoid case like (1081** - 14) ****/
           _2 LENGTH=200 LABEL='Range (without censored values)'

    FROM (SELECT DISTINCT paramcd, trtpn, stratum, strip(put(aval, best.))||strip(cen) AS avalc length=100,
    '    ('||strip(put(min(aval), best.)||strip(cen))||' - '||strip(put(max(aval), best.)||strip(cen))||')' AS _1  'Range (including censored values)'
                    FROM sum_cens
                    /**** range including censored values ****/
                    WHERE _censor_ EQ 1
                    GROUP BY trtpn
                    HAVING aval EQ min(aval) OR aval EQ max(aval)) AS aaa
         LEFT JOIN (SELECT DISTINCT trtpn,
                        '    ('||strip(put(min(aval), best.)||strip(cen))||' - '||strip(put(max(aval), best.)||strip(cen))||')' AS _2
                    FROM sum_cens
                    /**** range without censored values ****/
                    WHERE _censor_ EQ 0
                    GROUP BY trtpn) AS bbb ON aaa.trtpn=bbb.trtpn
    GROUP BY paramcd, aaa.trtpn
    ORDER BY paramcd, trtpn    ;
QUIT;

PROC TRANSPOSE DATA=km_r OUT=km_r PREFIX=ttt;
    BY paramcd;
    ID trtpn;
    VAR _1 _2;
    format trtpn ;
RUN;

PROC DELETE data=sum1;
RUN;

**************************** quantile ****;

DATA km_q;
    SET sum2 END=lastrec;
    LENGTH weeks $200;
    IF missing(lowerlimit) THEN lowerlimit=.A;
    IF missing(upperlimit) THEN upperlimit=.A;
    IF missing(estimate) THEN estimate=.A;
    weeks=put(estimate, 5.0)||' ['||strip(put(lowerlimit, 5.0))||';'||strip(put(upperlimit, 5.0))||']';
    RETAIN _ft1flag;
    IF missing(lowerlimit) OR missing(upperlimit) OR missing(estimate) THEN _ft1flag='Y';
    IF lastrec THEN CALL symput('_ft1', strip(_ft1flag));
RUN;

PROC SORT DATA=km_q;
    BY paramcd percent;
RUN;

PROC TRANSPOSE DATA=km_q OUT=km_q (RENAME=(percent=group2)) PREFIX=ttt;
    BY paramcd percent;
    ID trtpn;
    VAR weeks;
    format trtpn;
RUN;

PROC DELETE data=sum2;
RUN;

************************************ all together ****;

DATA final (DROP=paramcd);
    LENGTH ttt&__t1. ttt&__t2. ttt&__t3. _label_ _name_ paramcd $500;
    SET km_c (IN=aaa) km_q (IN=bbb) km_r (IN=ccc) ;
    IF aaa THEN DO;
        group2=input(compress(_name_, '_'), ??best.);
        group1=1;
        _name_=' ';
    END;
    IF bbb THEN DO;
        group1=2;
        _name_ = "(Weeks)";
        IF group2 EQ 50 THEN _label_='Median [95% CI]';
        ELSE _label_=strip(put(group2, best.))||'th percentile [95% CI]';
    END;
    IF ccc THEN DO;
        group2=input(compress(_name_, '_'), ??best.)+100;
        group1=2;
        _name_='(Weeks)';
    END;
    LABEL _label_='#'
          _name_='#'
          group1=' '
          group2=' '
          ttt&__t1.="Elinzanetant 120mg"
          ttt&__t2.="Placebo - Elinzanetant 120mg"
          ttt&__t3.="Total"
          ;
RUN;

************************************ define footnote for unestimable data ****;
DATA _NULL_;
    IF NOT missing(strip("&_ft1.")) THEN ftno1="A: Value cannot be estimated due to censored data.";
    ELSE ftno1="";
    CALL symput("_ftn1", strip(ftno1));
RUN;

%MTITLE;

%datalist(
    data     = final
  , by       = group1 group2 _label_ _name_
  , var      = ttt&__t1. ttt&__t2.
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