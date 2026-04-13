/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name     = l_10_2_4_ie_demo_not_met);
/*
 * Purpose          : Inclusion and exclusion criteria not met
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gniiq (Mayur Parchure) / date: 13OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/l_10_2_4_ie_demo_not_met.sas (gniiq (Mayur Parchure) / date: 13OCT2023)
 ******************************************************************************/

%extend_data(indat = ads.adsl, outdat = adsl)

PROC SQL NOPRINT;
    CREATE TABLE ie1 AS
    SELECT a.*,b.SASR,b.SUBJID,b.TRT01PN
    FROM sp.ie AS a LEFT JOIN adsl AS b
    ON a.USUBJID=b.USUBJID;
QUIT;

DATA adie_01;
    SET ie1 (KEEP= SASR IETEST IESEQ iecat SUBJID IEORRES TRT01PN SUBJID);
    LENGTH IEORRES2 $3.;
    IF iecat='INCLUSION' THEN iecatn = 1;
    ELSE IF iecat='EXCLUSION' THEN iecatn = 2;
    IF IEORRES = "N" THEN IEORRES2 = "NO";
    ELSE IF IEORRES = "Y" THEN IEORRES2 = "YES";
    SUB_ASR= SASR ;
    LABEL IECAT                   = "Inclusion/#Exclusion#Category";
    LABEL IETEST                   = "Inclusion/Exclusion#Criterion";
    LABEL IEORRES2                 = "Inclusion/#Exclusion#Answer";
    LABEL SUB_ASR                  = "Subject Identifier/#Age/ Sex/ Race";
    LABEL &treat_var_listings_part = "Planned Treatment Group";
RUN;

PROC SORT DATA = adie_01 NODUPKEY DUPOUT = chk_dup;
    BY SUBJID iecatn IETEST;
RUN;

%MTITLE;

%datalist(
    data     = adie_01
  , page     = &treat_var_listings_part.
  , by       = SUBJID SUB_ASR
  , var      = IECAT IETEST IEORRES2
  , order    = SUBJID IECATN
  , freeline =
  , optimal  = yes
  , maxlen   = 80
  , hsplit   = '#'
  , bylen    = 25
)

%endprog()
