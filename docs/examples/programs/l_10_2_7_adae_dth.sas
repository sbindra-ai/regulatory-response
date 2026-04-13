/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog( name     = l_10_2_7_adae_dth);
/*
 * Purpose          : Deaths not attributed to an adverse event (SAF)
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gniiq (Mayur Parchure) / date: 13OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/l_10_2_7_adae_dth.sas (gniiq (Mayur Parchure) / date: 13OCT2023)
 ******************************************************************************/

%m_create_ads_view(
    adsDomain = adae
  , outDat    = adaeall
  , adslVars  = SASR TRT01AN TRTSDT TRTEDT DTHFL DTHDT SAFFL
)

DATA adae1(RENAME=(DTHDT=DTHDTL));
    SET adaeall;
    WHERE  &SAF_COND. AND DTHFL='Y';
RUN;

%extend_data(indat = adae1, outdat = adae)

DATA dth_final;
        SET adae(IN=a);
        BY STUDYID USUBJID SASR;

        ATTRIB SASR   LENGTH=$40   LABEL='Subject Identifier/#Age/ Sex/#Race'
               DATES   LENGTH=$28  LABEL='Study Drug Start#Date/Stop Date'
               DTHDTL              LABEL='Date of Death'
               RELDAY  LENGTH=$20  LABEL='Start/ Stop (Relative to Treatment)'
               TRT01AN             LABEL='Actual Treatment Group'
               AEDECOD             LABEL='AE (MedDRA Preferred Term)#With Fatal Outcome'
        ;
        DATES     = catx( ' / ', put(trtsdt, %varfmt(ads.adsl, trtsdt)), put(trtedt, %varfmt(ads.adsl, trtedt)));
        IF ~missing(DTHDTL) THEN DO;
        IF  ~missing(trtsdt) AND ~missing(DTHDTL) THEN rel2start= (DTHDTL -trtsdt+1);
        IF  ~missing(trtedt) AND ~missing(DTHDTL) THEN rel2stop= (DTHDTL -trtedt);
        END;

        RELDAY    = catx(' / ', put(rel2start, 4.), put(rel2stop, 4.));
        IF ARELN=1 THEN aerel='Yes' ;
        ELSE IF ARELN=0 THEN aerel='No' ;
RUN;

/*"Investigator-Reported Cause of Death" is not captured in the study therefore not kept in the output*/

%MTITLE;

%datalist(
    data     = dth_final
  , by       = &treat_arm_a.
  , var      = SASR DATES DTHDTL RELDAY
  , freeline = &treat_arm_a.
  , optimal  = yes
  , hsplit   = '#'
)

%endprog();