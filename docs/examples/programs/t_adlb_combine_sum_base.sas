/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
    %iniprog(name = t_adlb_combine_sum_base);
/*
 * Purpose          : Number of subjects by combined hepatic safety laboratory categories relative to baseline
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
/* Changed by       : ereiu (Katharina Meier) / date: 05DEC2023
 * Reason           : # Simplify code (use &extend_rule_disp_12_ezn_52_a_afl.,...)
 *                    # Update header
 *                    # Use paramn instead of _ord
 *                    # Add splited treatment label
 *                    # Use %m_switcher_avisit2
 ******************************************************************************/
/* Changed by       : gdcpl (Derek Li) / date: 05DEC2023
 * Reason           : add codes to keep only one record for each subject, @Katharina, if you think
 *                    it is ok, please remove my name here
 ******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 07DEC2023
 * Reason           : Update %m_switcher_avisit2
 ******************************************************************************/
/* Changed by       : gdcpl (Derek Li) / date: 26FEB2024
 * Reason           : replace &lb_avisit_selection. by avisitn>5
 ******************************************************************************/

%LET mosto_param_class = %scan(&extend_var_disp_12_ezn_52_a, 1, '@');

* Load and extend data;
%load_ads_dat(adlb_view, adsDomain = adlb , where = 95009000 le paramn le 95013000 and avisitn>5, adslWhere = &saf_cond.); * Select CCRIT 9 to 13;
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

* Prepare data;
%m_switcher_avisit2(
    indat  = adlb_ext
  , trtvar = &mosto_param_class.
  , byvar  = paramcd
);

DATA adlb_switch;
    SET adlb_ext;
    *%m_switcher_avisit();
    format &mosto_param_class. _trtgrp_split.;
    FORMAT critflall $x_ny.;
    attrib critall format = $200. label = 'Category';
    critall   = put(paramcd,$x_lbpar.);
    critflall = avalc;
run;

**?to keep only one record for each usubjid, if have Y, keep Y, otherwise keep N;
proc sort data=adlb_switch;
    by studyid usubjid paramcd critflall;
RUN;

data adlb_switch;
    set adlb_switch;
    by studyid usubjid paramcd;
    if last.paramcd;
RUN;

* Output;
%set_titles_footnotes(
    tit1 = "Table: Number of subjects by combined hepatic safety laboratory categories relative to baseline &saf_label"
  , ftn1 = "n = number of subjects with parameter assessments done at baseline and at post-baseline."
  , ftn2 = "For OASIS 3, the event onset is up to day 182 (inclusive) for EZN 120 mg (week 1-26)."
  , ftn3 = "Unscheduled visits were included in the analysis."
  , ftn4 = "AST = Aspartate Aminotransferase, ALT = Alanine Transferase, ALP = Alkaline Phosphatase."
);

%LET MOSTOCALCPERCWIDTH=NO;

%insertoptionrtf(namevar = avisit,  width = 91.0pt,  keep = n, overwrite = no);
%insertoptionrtf(namevar = critall, width = 311.0pt, keep = n, overwrite = no);
%insertoptionrtf(namevar = _varl_,  width = 21.0pt,  keep = n, overwrite = no);
%insertoptionrtf(namevar = _cptog1, width = 55.0pt,  keep = n, overwrite = no);
%insertoptionrtf(namevar = _cptog2, width = 55.0pt,  keep = n, overwrite = no);
%insertoptionrtf(namevar = _cptog3, width = 61.0pt,  keep = n, overwrite = no);

%freq_tab(
    data     = adlb_switch
  , data_n   = adsl_ext
  , var      = critflall
  , subject  = usubjid
  , by       = paramn critall
  , total    = no
  , order    = paramn
  , basepct  = n
  , hlabel   = yes
  , complete = all
  , maxlen   = 15
  , hsplit   = '#'
  , bylen    = 20
);

%LET MOSTOCALCPERCWIDTH=optimal;

%endprog();