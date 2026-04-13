/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(
      name     = l_10_1_6_spda_batch);
/*
 * Purpose          : Batch listing
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gniiq (Mayur Parchure) / date: 31OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/l_10_1_6_spda_batch.sas (gniiq (Mayur Parchure) / date: 18OCT2023)
 ******************************************************************************/

PROC SQL;
    CREATE TABLE da1 AS
           SELECT a.*, b.RANDNO, b.&treat_var, b.SUBJID
           FROM sp.da AS a LEFT JOIN ads.adsl AS b
           ON a.USUBJID = b.USUBJID
           WHERE DATESTCD='DISPAMT';
QUIT;

%extend_data(indat = ads.adsl, outdat = adsl)

%m_create_dtl(
    inputds = da1
  , varname = dadtl
)

DATA da_final(KEEP= SUBJID USUBJID VISITNUM DADTL RANDNO &treat_var DASMNUM DAREFID DTL);
     SET da1;
     if (~missing(dadtl) and dadtl ne '---------') then dtl=input(dadtl,date9.);
     LABEL dadtl      = 'Study Medication#Dispensation Date';
     LABEL randno     = 'Randomization#Number';
     LABEL visitnum   = 'Visit';
     LABEL dasmnum    = 'Study Medication#Number';
     LABEL darefid    = 'Pack Batch#Number';
     LABEL subjid     = 'Subject#Identifier';
     LABEL &treat_var = 'Actual#Treatment';
RUN;

proc sort data=da_final;
    by SUBJID dtl;
RUN;

%MTITLE;

%datalist(
    data     = da_final
  , by       = SUBJID
  , var      = RANDNO  DADTL &treat_var DASMNUM DAREFID
  , order    = USUBJID DTL
  , optimal  = YES
  , maxlen   = 30
  , hsplit   = "#"
  , bylen    = 20
  , layout   = Standard
  , hc_align = CENTER
  , hn_align = CENTER
);
%endprog();