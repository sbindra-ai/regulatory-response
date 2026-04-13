/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = d_advs);
/*
 * Purpose          : Derivation of ADVS
 * Programming Spec : 
 * Validation Level : 2 - Verification by Double Programming
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gkbkw (Ashutosh Kumar) / date: 10AUG2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/d_advs.sas (gkbkw (Ashutosh Kumar) / date: 25JUL2023)
 ******************************************************************************/

%let adsDomain = ADVS;
%early_ads_processing(adsDat = &adsDomain.)

%m_visit2avisit(indat=&adsDomain.,outdat=&adsDomain.,EOT=EOT);


%m_create_saf_baseline(data=advs);
Data advs;
    set advs;
    /*remapping screening to baseline in case baseline visit is not available and screening visit used as baseline*/
    if ablfl eq "Y" then do;
        if visitnum eq 0 then avisitn =5;
    END;
    where VSTESTCD ne "VSALL";
RUN;

%m_create_saf_anlflag(data=advs);
*** Custom Derivation;


%late_ads_processing(adsDat = &adsDomain.)

%endprog()