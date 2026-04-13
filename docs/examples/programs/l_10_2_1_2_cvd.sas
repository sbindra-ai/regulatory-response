/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(
       name     = l_10_2_1_2_cvd);
/*
 * Purpose          : Listing of subjects affected by COVID-19 pandemic related study disruption
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gniiq (Mayur Parchure) / date: 21OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/l_10_2_1_2_cvd.sas (gniiq (Mayur Parchure) / date: 21OCT2023)
 ******************************************************************************/

%m_create_ads_view(
    adsDomain = addv
  , outDat    = addvall
  , adslVars  = SASR  COUNTRY INVNAM EP1FL EP1DVFL &TREAT_VAR
)

DATA addv1;
    SET addvall;
    WHERE EP1DVFL='Y' AND EP1FL ='Y';
RUN;

%extend_data(indat = addv1, outdat = addv)

%m_create_ads_view(
    adsDomain = adae
  , outDat    = adaeall
  , adslVars  = SASR  COUNTRY INVNAM EP1FL EP1SEI &TREAT_VAR
)

DATA adae1;
    SET adaeall;
    WHERE EP1SEI ='Y' AND EP1FL ='Y';
RUN;

%extend_data(indat = adae1, outdat = adae)

%m_create_ads_view(
    adsDomain = adds
  , outDat    = addsall
  , adslVars  = SASR COUNTRY INVNAM EP1FL EP1BDCSI &TREAT_VAR
)

DATA adds1;
    SET addsall;
    WHERE EP1BDCSI ='Y' AND EP1FL ='Y';
RUN;

%extend_data(indat = adds1, outdat = adds)

PROC SQL NOPRINT;
    CREATE TABLE EC_1 AS
       SELECT a.USUBJID, a.ECADJ, b.SASR, b.COUNTRY, b.SITEID,
       b.EP1FL, b.EP1SEI
       FROM sp.ec AS a
       INNER JOIN ads.adsl AS b
       ON a.USUBJID=b.USUBJID
       WHERE b.EP1FL ='Y' AND b.EP1SEI = 'Y'
     ;
QUIT;

DATA cov_final;
    LENGTH SUB_ASR $70 DISRUP $300;
    SET addv(IN=a) adae(IN=b) adds(IN=c)  EC_1(IN=d);
    BY USUBJID;
    SUB_ASR = SASR;
    IF a THEN disrup="Protocol deviation(s): COVID-19 pandemic related - "|| DVTERM ;
    ELSE IF b THEN disrup="Adverse event(s): "|| AEDECOD ;
    ELSE IF c THEN disrup= propcase(DSDECOD)|| ": COVID-19 pandemic related - "|| DSTERM ;
    ELSE IF d THEN disrup= "Dose modification(s): COVID-19 pandemic related - "|| ECADJ ;
    ELSE disrup='';

    LABEL SUB_ASR    = "Subject Identifier/#Age/ Sex/#Race";
    LABEL COUNTRY    = "Country/#Region";
    LABEL INVNAM     = "Investigator";
    LABEL DISRUP     = "Details on COVID-19 pandemic related study disruption";
    LABEL &TREAT_VAR = "Actual Treatment Group";
RUN;


PROC SORT DATA=cov_final;
    BY COUNTRY INVNAM SUB_ASR  ;
RUN;

%MTITLE;

%datalist(
    data     = cov_final
  , page     = &TREAT_VAR
  , by       = COUNTRY INVNAM SUB_ASR
  , var      = DISRUP
  , order    = USUBJID
  , order_var=
  , optimal  = N
  , maxlen   = 70
  , hsplit   = "#"
  , bylen    = 30
  , hc_align = CENTER
  , hn_align = CENTER
);


%endprog();