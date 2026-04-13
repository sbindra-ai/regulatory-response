/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_1_1_adds_screen);
/*
 * Purpose          : Subjects who did not complete or pass screening
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gniiq (Mayur Parchure) / date: 13OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/l_10_2_1_1_adds_screen.sas (gniiq (Mayur Parchure) / date: 13OCT2023)
 ******************************************************************************/

%m_create_ads_view(adsDomain = adds, outDat = addsall)

%extend_data(indat = addsall, outdat = adds)

%m_create_dtl(inputds = adds, varname = DSSTDTL)

*<*****************************************************************************;
*< Split Dataset to have the correct value for Date of Last Visit for subjects ;
*<*****************************************************************************;

PROC SORT DATA=adds(WHERE=(DSDECOD NOT IN ('COMPLETED' 'ADVERSE EVENT') AND DSCAT EQ 'DISPOSITION EVENT' AND Epoch="SCREENING")) OUT=adds_1;
     BY USUBJID;
RUN;

PROC SORT DATA=adds(WHERE=(DSDECOD = 'DATE OF LAST VISIT')) OUT=adds_2(KEEP=USUBJID DSSTDTL RENAME=(DSSTDTL=_LASTVIS));
     BY USUBJID;
RUN;

*<*****************************************************************************;
*< Merge both datasets as a left join to have the date of last visit           ;
*<*****************************************************************************;
PROC SQL NOPRINT;
    CREATE TABLE adds_3 AS
    SELECT a.USUBJID,a.DSDECOD,a.SASR,
    b._LASTVIS, c.IECAT,c.IETEST,c.IEORRES AS IEORRES1
    FROM adds_1 AS a
    LEFT JOIN adds_2 AS b
    ON a.USUBJID=b.USUBJID
    LEFT JOIN sp.ie AS c
    ON a.USUBJID=c.USUBJID;
QUIT;

DATA adds_4;
     SET adds_3;
     IF IEORRES1 = "Y" THEN IEORRES = "YES";
     ELSE IF IEORRES1 = "N" THEN IEORRES = "NO";
     LABEL _LASTVIS = "Date of Last Visit";
     LABEL DSDECOD = 'Primary Reason';
     LABEL IETEST = 'Inclusion/#Exclusion#Criterion';
     LABEL IECAT = 'Inclusion/#Exclusion#Category'  ;
     LABEL IEORRES = 'Inclusion/#Exclusion#Answer'  ;
     LABEL SASR = "Subject Identifier/#Age/ Sex/ Race";
RUN;

PROC SORT DATA= adds_4;
    BY SASR;
RUN;
*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%MTITLE;

%datalist(
    data     = adds_4
  , by       = SASR
  , var      = _LASTVIS DSDECOD IECAT IETEST IEORRES
  , freeline = SASR
  , together = SASR
  , optimal  = yes
  , maxlen   = 28
  , hsplit   = "#"
  , bylen    = 13
  , hc_align = CENTER
  , hn_align = CENTER
)

%endprog()
