/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = d_adex_pre);
/*
 * Purpose          : to re-program ADEX
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gmrpb (Fiona Yan) / date: 11JUL2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/d_adex_pre.sas (gmrpb (Fiona Yan) / date: 20JUN2023)
 ******************************************************************************/
%let adsDomain = ADEX;

*<*****************************************************************************;
*< Early ADS processing;
*<*****************************************************************************;

%early_ads_processing(adsDat = &adsDomain., adsLib = ADS)

*<*****************************************************************************;
*< Late ADS processing;
*<*****************************************************************************;

data &adsDomain.;
    set &adsDomain.;
    ** temporary APERIOD created for _adamap_adsl_trt and will be removed in final ADEX;
    aperiod = 1;
    IF taetord=3 and exspid = '2' THEN aperiod = 2;

    PARAMTYP = '';

    ** below are placeholder variable to remove the warning due to ASEQ in non-final late processing;
    ** will be re-derived in d_adex;
    parcat1='';
    parcat2='';
    aphase='';
    trtan=.;
RUN;

** since finalise is set to N in late processing, we need to explicitly assign the library to ads;
data ads.&adsDomain.;
    set &adsDomain.;
RUN;

%late_ads_processing(adsDat = ads.&adsDomain., finalise = N)

%endprog()


