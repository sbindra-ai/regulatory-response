/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
   %LET prog = #runall_21561_01_ads_metadata;
/*
 * Purpose          : Start all programs, related to that study.
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : eokcw (Vijesh Shrivastava) / date: 26JUL2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/#runall_21562_01_ads_metadata.sas (eokcw (Vijesh Shrivastava) / date: 28JUL2022)
 ******************************************************************************/

*******************************************************************************;
*< Initialize study;
*******************************************************************************;
%initsystems(initstudy=5, spro=3, adamap=2, alsc=2, dtools=2, docfish = 2, mosto=7);
%initstudy(iniProgram=start.sas);

%GLOBAL default_createRTF;      *<-; %LET default_createRTF   = N; *no need to create RTFs;

*******************************************************************************;
*< Copy project adsmeta and global AD as start point to study adsmeta: ;
*******************************************************************************;
%cleanlib(lib     = adsmeta, complete = Y);
%copylib(
    fromlib = adsm_c_p
  , tolib   = adsmeta
  , ignore  = ADMK ADDA ADCE ADFACE
);


*** Remove ADMK and ADDA from ADSMETA.AD from 21652 study;

data adsmeta.ad;
    set adsmeta.ad;
    if memname in ('ADDA' 'ADMK' 'ADCE' 'ADFACE') then delete;
RUN;

*** Include individual metadata program if any Study specific changes are required;
%INCLUDE "&PRGDIR./adsmeta_adae.sas";
%INCLUDE "&PRGDIR./adsmeta_adcm.sas";
%INCLUDE "&PRGDIR./adsmeta_adds.sas";
%INCLUDE "&PRGDIR./adsmeta_addv.sas";
%INCLUDE "&PRGDIR./adsmeta_adex.sas";
%INCLUDE "&PRGDIR./adsmeta_adfapr.sas";
%INCLUDE "&PRGDIR./adsmeta_adlb.sas";
%INCLUDE "&PRGDIR./adsmeta_admh.sas";
%INCLUDE "&PRGDIR./adsmeta_adpr.sas";
%INCLUDE "&PRGDIR./adsmeta_adqs.sas";
%INCLUDE "&PRGDIR./adsmeta_adqshfss.sas";
%INCLUDE "&PRGDIR./adsmeta_adrp.sas";
%INCLUDE "&PRGDIR./adsmeta_adsl.sas";
%INCLUDE "&PRGDIR./adsmeta_adsv.sas";
%INCLUDE "&PRGDIR./adsmeta_adtte.sas";
%INCLUDE "&PRGDIR./adsmeta_advs.sas";
%INCLUDE "&PRGDIR./adsmeta_adxk.sas";


***************************************************************************;
*< Clean up;
***************************************************************************;
%endprog;