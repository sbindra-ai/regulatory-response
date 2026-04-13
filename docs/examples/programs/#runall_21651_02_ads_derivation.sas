/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
   %LET prog = #runall_21651_02_ads_derivation;
/*
 * Purpose          : Create all ADS data sets.
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : eokcw (Vijesh Shrivastava) / date: 26JUL2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/#runall_21652_02_ads_derivation.sas (eokcw (Vijesh Shrivastava) / date: 28JUL2022)
 ******************************************************************************/
/* Changed by       : gmrpb (Fiona Yan) / date: 28JUL2023
 * Reason           : move %check_ads_dat to another temp program
 ******************************************************************************/
/* Changed by       : gkbkw (Ashutosh Kumar) / date: 08AUG2023
 * Reason           : changed EVA version to 2
 ******************************************************************************/
/* Changed by       : gmrpb (Fiona Yan) / date: 19DEC2023
 * Reason           : Update inimode to ANALYSIS for unblinded data
 ******************************************************************************/

%initsystems(initstudy=5, mosto=7, spro=3, adamap=2, gral=4, eva = 2, poster = 1, alsc = 2, dtools = 2);
%initstudy(inimode = ANALYSIS);

%GLOBAL default_createRTF;      *<-; %LET default_createRTF   = N; *no need to create RTFs;

%cleanlib(lib = ADS);

%LET DEFAULT_Print2File=N;

*** D_FORMATS;
%INCLUDE "&PRGDIR./d_formats.sas";

%INCLUDE "&PRGDIR./d_advs.sas";
%INCLUDE "&PRGDIR./d_adex_pre.sas";
%INCLUDE "&PRGDIR./d_adsl.sas";
%INCLUDE "&PRGDIR./d_adex.sas";
%INCLUDE "&PRGDIR./d_adsv.sas";
%INCLUDE "&PRGDIR./d_adae.sas";
%INCLUDE "&PRGDIR./d_adcm.sas";
%INCLUDE "&PRGDIR./d_adds.sas";
%INCLUDE "&PRGDIR./d_addv.sas";
%INCLUDE "&PRGDIR./d_adfapr.sas";
%INCLUDE "&PRGDIR./d_adlb.sas";
%INCLUDE "&PRGDIR./d_admh.sas";
%INCLUDE "&PRGDIR./d_adpr.sas";
%INCLUDE "&PRGDIR./d_adqs.sas";
%INCLUDE "&PRGDIR./d_adqshfss.sas";
%INCLUDE "&PRGDIR./d_adrp.sas";
%INCLUDE "&PRGDIR./d_adtte.sas";
%INCLUDE "&PRGDIR./d_adxk.sas";

/******************************************************************************
 * End of program
 ******************************************************************************/
%endprog()