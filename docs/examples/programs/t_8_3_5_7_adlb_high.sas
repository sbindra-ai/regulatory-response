/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_3_5_7_adlb_high  );
/*
 * Purpose          : Treatment-emergent high laboratory abnormalities
 *                   by laboratory category and treatment: number of subjects
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 30NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/t_8_3_5_7_adlb_high.sas (emvsx (Phani Tata) / date: 20NOV2023)
 ******************************************************************************/


%macro sbgrp(cond=, arm=, label=);

%load_ads_dat(
    adlb_view
  , adsDomain = adlb
  , adslWhere = &cond. and n(&arm.)
  , adslVars  = &arm. saffl fasfl
)

%load_ads_dat(adsl_view , adsDomain = adsl , where =  &saf_cond );

%extend_data(indat = adlb_view , outdat = adlb )
%extend_data(indat = adsl_view  , outdat = adsl) ;

data adlb;
    set adlb
        (where=  (&cond. and anl01fl="Y"
        and not missing(anrind)  )
        );
    %M_PropIt(Var=parcat1);*changing Parcat1 to sentence case*;
    parcat1 = parcat1_prop ;
RUN;

proc sort data = adlb   out=adlb3  ;
    by usubjid   paramn avisitn;
    where avisitn ne . and aval ne . ;
run;

%MTITLE;

%cond_incidence_tab(
    data               = adlb3
  , data_n             = ads.adsl(where=(&cond. and not missing(&arm.)))
  , subject            = &subj_var
  , group              = parcat1   paramn
  , class              = &arm.
  , Total              = No
  , abnormal_condition = ANRIND ="HIGH"  and  TRTEMFL="Y"
  , baseline_condition = ablfl eq "Y" and anrind in ("LOW" "NORMAL")
  , collabel           = Laboratory variable
  , optimal            = YES
  , hsplit             = "#"
  , splitby            = NO
  , maxlen              = 30
  , zeropct             = YES
 )

%mend sbgrp;

%sbgrp(cond=&saf_cond., arm= &treat_var., label=&saf_label.);

%endprog;
