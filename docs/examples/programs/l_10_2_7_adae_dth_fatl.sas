/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(
       name     = l_10_2_7_adae_dth_fatl
   );
/*
 * Purpose          : Deaths: adverse events with fatal outcome (SAF)
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gniiq (Mayur Parchure) / date: 13OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/l_10_2_7_adae_dth_fatl.sas (gniiq (Mayur Parchure) / date: 13OCT2023)
 ******************************************************************************/

%m_create_ads_view(
    adsDomain = adds
  , outDat    = addsall
)

DATA adds1;
    SET addsall;
    WHERE DSDECOD IN ('DEATH' 'DECEASED') AND &SAF_COND;
RUN;

%m_create_dtl(
    inputds = adds1
  , varname = DSSTDTL
)

%extend_data(indat = adds1, outdat = adds)

%m_create_ads_view(
    adsDomain = adae
  , outDat    = adaeall
  , adslVars  = SASR SAFFL
)

DATA adae1;
    SET adaeall;
    WHERE &SAF_COND AND AESDTH='Y';
RUN;

%extend_data(indat = adae1, outdat = adae)

DATA dth_final;
        MERGE adds(IN=a) adae(IN=b DROP= SAFFL ADSNAME ASEQ EPOCH APHASE ASTDT ASTDY USUBJID_ORI EXTEND_COND);
        BY STUDYID USUBJID SASR;
        IF a OR b;

        ATTRIB SASR1   LENGTH=$40  LABEL='Subject Identifier/#Age/ Sex/#Race'
               DATES   LENGTH=$28  LABEL='Study Drug Start#Date/Stop Date'
               ASTDT             LABEL='Date of Death'
               RELDAY  LENGTH=$20  LABEL='Start/ Stop (Relative to Treatment)'
               AEDECOD             LABEL='AE (MedDRA Preferred Term)#With Fatal Outcome'
               AEREL1   LENGTH=$7   LABEL='Relationship to#Study Drug'
               TRT01AN             LABEL='Actual Treatment Group'
        ;
        SASR1      = sasr;
        DATES     = catx( ' / ', put(trtsdt, %varfmt(ads.adsl, trtsdt)), put(trtedt, %varfmt(ads.adsl, trtedt)));

        IF ~missing(DSSTDTL) THEN DO;
        IF  ~missing(trtsdt) THEN rel2start= (input(DSSTDTL,date9.)-trtsdt+1);
        IF  ~missing(trtedt) THEN rel2stop= (input(DSSTDTL,date9.)-trtedt);
        END;

        RELDAY    = catx(' / ', put(rel2start, 4.), put(rel2stop, 4.));
        IF ARELN=1 THEN aerel1='Yes' ;
        ELSE IF ARELN=0 THEN aerel1='No' ;
        ELSE IF ARELN=. THEN aerel1='Missing' ;
RUN;

%MTITLE;

%datalist(
    data     = dth_final
  , by       = &treat_arm_a.
  , var      = SASR1 DATES ASTDT RELDAY AEDECOD AEREL1
  , freeline = &treat_arm_a.
  , optimal  = yes
  , hsplit   = '#'
)

%endprog();