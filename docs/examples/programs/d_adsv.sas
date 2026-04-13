/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = d_adsv);
/*
 * Purpose          : Derivation of ADSV
 * Programming Spec :
 * Validation Level : 2 - Verification by Double Programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gmrpb (Fiona Yan) / date: 16MAY2023
 * Reference prog   :
 ******************************************************************************/
%let adsDomain = ADSV;

%early_ads_processing(
    adsDat = &adsDomain.
  , adsLib = work
)

%m_visit2avisit(indat=&adsDomain.,outdat=&adsDomain.,EOT=EOT);

*** Custom Derivation;
DATA ADS.&adsDomain.;
    set &adsDomain.;
RUN;

%late_ads_processing(adsDat = ADS.&adsDomain.)

%endprog()
