/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = d_adrp);
/*
 * Purpose          : Derivation of ADRP
 * Programming Spec : 
 * Validation Level : 2 - Verification by Double Programming
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gmrnq (Susie Zhang) / date: 27JUL2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/d_adrp.sas (gmrnq (Susie Zhang) / date: 24JUL2023)
 ******************************************************************************/


%let adsDomain = ADRP;

*<*****************************************************************************;
*< Early ADS processing;
*<*****************************************************************************;
%early_ads_processing(adsDat = ADS.&adsDomain.)

%m_visit2avisit(indat=ads.&adsDomain.,outdat=ads.&adsDomain.,EOT=WEEK26);

*<*****************************************************************************;
*< Remove RPALL records;
*<*****************************************************************************;
data ads.&adsDomain.;
    set ads.&adsDomain.(where=(paramcd ^="RPALL"));
RUN;

*<*****************************************************************************;
*< Late ADS processing;
*<*****************************************************************************;


%late_ads_processing(adsDat = ADS.&adsDomain.)

%endprog()

