/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name     = l_10_2_4_adds_demo_enr_rd);
/*
 * Purpose          : Enrollment and randomization
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gniiq (Mayur Parchure) / date: 21FEB2024
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/l_10_2_4_adds_demo_enr_rd.sas (gniiq (Mayur Parchure) / date: 13OCT2023)
 ******************************************************************************/

%m_create_ads_view(
    adsDomain = adds
  , outDat    = addsall
)

DATA adds1;
    SET addsall;
   WHERE ENRLFL='Y' AND RANDFL='Y';
RUN;

%extend_data(indat = adds1, outdat = adds)

%m_create_dtl(
    inputds = adds
  , varname = DSSTDTL
)

DATA adds_01;
     SET adds(WHERE=(DSTERM ='INFORMED CONSENT OBTAINED' AND DSSCAT = 'INFORMED CONSENT')); /*INFORMED CONSENT OBTAINED */
RUN;

DATA adds_02 (DROP= DSDECOD);
     SET adds(WHERE=(DSDECOD ='RANDOMIZED' ) KEEP=USUBJID DSSTDTL DSDECOD RENAME=(DSSTDTL= _randdt) );   /*RANDOMIZED*/
RUN;

PROC SQL NOPRINT;
    CREATE TABLE sv_ AS
           SELECT a.*, b.ENRLFL, b.RANDFL
           FROM sp.sv AS a LEFT JOIN ads.adsl AS b
           ON a.usubjid=b.usubjid
           WHERE b.ENRLFL='Y' AND b.RANDFL='Y';
QUIT;

DATA sv(DROP=ENRLFL );
    SET sv_;
    IF epoch ='SCREENING' THEN epochn=1;
    ELSE IF epoch ='TREATMENT' THEN epochn=2;
    ELSE IF epoch ='FOLLOW-UP' THEN epochn=3;
RUN;

%m_create_dtl(inputds=sv, varname= SVSTDTL);

PROC SORT DATA=sv;
     BY USUBJID EPOCHN SVSTDTC;
RUN;

DATA adsv_01;
     SET sv(WHERE=(epoch='SCREENING' /*100 - SCREENING*/) KEEP=USUBJID VISIT VISITNUM SVSTDTL EPOCHN EPOCH);
     BY USUBJID;
     IF FIRST.USUBJID;
     LABEL SVSTDTL = "Screening Visit Date" ;
RUN;

PROC SORT DATA=adds_01;
     BY usubjid;
RUN;

PROC SORT DATA=adds_02;
     BY usubjid;
RUN;

PROC SORT DATA=adsv_01;
     BY usubjid;
RUN;

DATA adds_04;
     MERGE adds_01 (DROP=epoch IN=a) adds_02(IN=b) adsv_01(IN=c);
     BY USUBJID;

     LABEL DSSTDTL = "Informed Consent Date";
RUN;

PROC SQL NOPRINT;
    CREATE TABLE adsl AS
    SELECT a.USUBJID, a.INVNAM, a.RANDNO, a.SASR,b.INVID
    FROM ads.adsl AS a LEFT JOIN sp.dm AS b
    ON a.USUBJID=b.USUBJID
    ORDER BY a.USUBJID;
QUIT;

DATA adds_05;
     MERGE adds_04(IN=a ) adsl ;
     BY USUBJID SASR RANDNO;
     IF a;
     AMENDNO1=strip(put(AMENDNO,best.));
     LABEL SASR  = "Subject Identifier/#Age/ Sex/ Race";
     LABEL AMENDNO1 = "Protocol Amendment Number";
     LABEL SITEID  = "Trial Unit";
     LABEL _RANDDT  = "Date of Randomization";
     LABEL &treat_var_listings_part. = "Planned Treatment Group";
RUN;

%MTITLE;

%datalist(
    data    = adds_05
  , page    = &treat_var_listings_part.
  , by      = SASR
  , var     = SVSTDTL AMENDNO1 DSSTDTL SITEID INVID INVNAM RANDNO _RANDDT
  , hsplit          = "#"
  , optimal = YES
  , maxlen  = 13
  , space   = 1
  , bylen   = 21
)

%endprog()