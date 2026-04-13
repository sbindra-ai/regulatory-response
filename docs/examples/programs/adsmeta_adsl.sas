/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/Pool  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
  %iniprog(name = adsmeta_adsl);
/*
 * Purpose          : create ADSL metadata specification
 * Programming Spec :
 * Validation Level : 1 - verification by review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : eokcw (Vijesh Shrivastava) / date: 02AUG2022
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : gmrpb (Fiona Yan) / date: 01MAY2023
 * Reason           : add ICE variables for testing purpose
 ******************************************************************************/
/* Changed by       : gmrpb (Fiona Yan) / date: 27JUN2023
 * Reason           : update BMIGRPN to BMIGRyN
 ******************************************************************************/

%create_domain_meta(
    domain = ADSL
  , vars   = ADSNAME STUDYID USUBJID SUBJID UASR SASR RASR ASR SAFFL ENRLFL RANDFL FASFL SCRNFLFL SAFEXRE1 FASEXRE1
             COMPLFL RFSTDT RFENDT RFICDT DTHFL DTHDT TRTSDT TRTEDT LVDT RANDDT SITEID INVNAM AGE AGEU AGEGRyN SEX
             RACE ETHNIC ARMCD ARM TRTxxPN TRTxxAN COUNTRY RANDNO REGIONyN WEIGHTBL HEIGHTBL BMIBL SMOKHXN EXNYOVLN
             BMIGRyN EDULEVEL SLASFL SLAEXRE1 RFXSTDT RFXENDT RFPENDT BRTHDT DCSREAS PHwSDT PHwEDT ISICAT
             EPwFL EPwSEI EPwBDCSI EPwDVFL EPwIEFL EPwODFL
);



%endprog;
