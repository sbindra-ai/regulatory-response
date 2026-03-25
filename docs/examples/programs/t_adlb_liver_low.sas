/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
    %iniprog(name = t_adlb_liver_low);
/*
 * Purpose          : Treatment-emergent low abnormalities by hepatic safety laboratory category and treatment: number of subjects (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gdcpl (Derek Li) / date: 19OCT2023
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 14NOV2023
 * Reason           : # Copy code from program t_adlb_high
 *                    # Restrict to paramcd in (&liver_param)
 *                    # Update title
 *                    # Use &lb_avisit_selection.
 ******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 08DEC2023
 * Reason           : # Remove &lb_avisit_selection.
 *                    # Exclude &lb_cat_urine. parameter
 *                    # Use splited treatment label / use outdat
 *                    # Use &extend_rule_disp_12_ezn_52_anofl. in adlb
 ******************************************************************************/
/* Changed by       : gdcpl (Derek Li) / date: 29MAR2024
 * Reason           : use TRTEFL1/TRTEFL2/TRTEMFL to replace TRTEMFL
 ******************************************************************************/

%LET mosto_param_class = %scan(&extend_var_disp_12_ezn_52_a, 1, '@');

* Load and extend data;
%load_ads_dat(adlb_view, adsDomain = adlb, where = paramcd in (&liver_param.) and paramcd not in (&lb_cat_urine.), adslWhere = &saf_cond.);
%load_ads_dat(adsl_view, adsDomain = adsl, where = &saf_cond.);

%extend_data(
    indat       = adlb_view
  , outdat      = adlb_ext
  , var         = &extend_var_disp_12_ezn_52_a.
  , extend_rule = &extend_rule_disp_12_ezn_52_anofl.
);

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , subj_var    = USUBJID
  , var         = &extend_var_disp_12_ezn_52_a.
  , extend_rule = &extend_rule_disp_12_ezn_52_a1.
);

data adlb_ext;
    set adlb_ext(rename=(trtemfl=_trtemfl));
    format &mosto_param_class. _trtgrp_split.;
    if missing(lbstat);
    format trtemfl $1.;
    if &mosto_param_class. in (1,2) then trtemfl=trtefl1;
    else if &mosto_param_class. in (4,6) then do;
        if cmiss(_trtemfl,trtefl2) ne 2 then trtemfl='Y';
    END;

    if missing(trtemfl) then trtemfl = "N"; * To avoid warning from %cond_incidence_tab;
RUN;

* Output;
%set_titles_footnotes(
    tit1 = "Table: Treatment-emergent low laboratory abnormalities by hepatic safety laboratory category and treatment: number of subjects &saf_label."
  , ftn1 = "The denominator (Den) represents the number of subjects at baseline with a normal or higher than normal laboratory assessment, and at least one valid laboratory value after start of treatment. "
  , ftn2 = "<cont>Subjects with missing or low abnormal values at baseline are not included in the denominator."
  , ftn3 = "The numerator (Num) represents the number of subjects with at least one low laboratory assessment during treatment-emergent window, and a normal or higher than normal laboratory assessment at baseline."
  , ftn4 = "For OASIS 3, measurements up to day 182 (inclusive) for EZN 120 mg (week 1-26) are considered."
  , ftn5 = "Unscheduled visits were included in the analysis."
);

%cond_incidence_tab(
    data               = adlb_ext
  , data_n             = adsl_ext
  , subject            = &subj_var
  , group              = parcat1 paramcd
  , total              = no
  , abnormal_condition = anrind = "LOW" and trtemfl = "Y"
  , baseline_condition = ablfl = "Y" and anrind in ("HIGH" "NORMAL")
  , collabel           = Laboratory variable
  , outdat             = tmp
  , optimal            = YES
  , hsplit             = "#"
  , splitby            = NO
);

%let _vars = %getDataValueList(tmpinp(WHERE = (keyword = 'VAR')), value);

data tmp;
    set tmp;
    array Avars $ &_vars.;
    do over Avars;
        Avars = tranwrd(Avars, "Num", "#Num");
    END;
RUN;

%mosto_param_from_dat(data = tmpinp, var = varlist)
%datalist(&varlist.)

%symdel _vars;
%endprog();