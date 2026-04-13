/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/Pool  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = d_addv);
/*
 * Purpose          : Derivation of ADDV
 * Programming Spec : 21651 Statistical analysis plan_v1.0.docx
 * Validation Level : 2 - Verification by Double Programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : epjgw (Roland Meizis) / date: 21JUN2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/d_addv.sas
 ******************************************************************************/


%let adsDomain = ADDV;
%early_ads_processing(
    adsDat       = &adsDomain.
  , addCTFormats = N
)
/******************************************************************************
 * Run custom derivations
 ******************************************************************************/

** None needed ;

/* Exclude Validity findings records (with missing IDREQIMD) as they will be in ADSL and ADXI domains */
DATA &adsDomain.;
  set &adsDomain. (where=(not missing(IDREQIMD)));
RUN;

%late_ads_processing(
    adsDat   = &adsDomain.
  , finalise = Y /* finalize and save in ADS */
)


%endprog()