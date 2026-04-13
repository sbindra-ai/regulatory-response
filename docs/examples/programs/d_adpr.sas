
/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/Pool  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = d_adpr);
/*
 * Purpose          : Derivation of ADPR
 * Programming Spec :
 * Validation Level : 2 - Verification by Double Programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : eokcw (Vijesh Shrivastava) / date: 25APR2022
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : eokcw (Vijesh Shrivastava) / date: 12JAN2023
 * Reason           : ###Reason###
 ******************************************************************************/
/* Changed by       : gmrpb (Fiona Yan) / date: 27FEB2023
 * Reason           : Update %iniprog parameter
 ******************************************************************************/


%let adsDomain = ADPR;

*<*****************************************************************************;
*< early ADS processing;
*<*****************************************************************************;


%early_ads_processing(adsDat = ADS.&adsDomain.)

%m_visit2avisit(indat=ads.&adsDomain.,outdat=ads.&adsDomain.,EOT=EOT);

/**** Custom Derivation;*/


*<*****************************************************************************;
*< Late ADS processing;
*<*****************************************************************************;


%late_ads_processing(adsDat = ADS.&adsDomain.)

%endprog()

