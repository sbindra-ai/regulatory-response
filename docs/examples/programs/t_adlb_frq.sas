/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
    %iniprog(name = t_adlb_frq);
/*
 * Purpose          : Laboratory data: Number of subjects by <<URINANALYSIS, categorical parameter>> and IA visit by IA visit and integrated analysis treatment group &saf_label
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
/* Changed by       : ereiu (Katharina Meier) / date: 07DEC2023
 * Reason           : # Update header
 *                    # Simplify code (use &extend_rule_disp_12_ezn_52_a_afl., ...)
 *                    # Use &lb_safety_param. and &lb_avisit_selection.
 *                    # One table per parcat1 and paramcd
 *                    # Use simple %freq_tab without loop per paramcd
 *                    # Use splited treatment label
 *                    # Use %m_switcher_avisit2
 ******************************************************************************/
/* Changed by       : gdcpl (Derek Li) / date: 14FEB2024
 * Reason           : remove paramcd from var
 ******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 16FEB2024
 * Reason           : Use &foot_w1_12., "&foot_ia_eot.", &foot_switcher_26_52.
 *                    # Add footnote  EoT = End of Treatment.
 ******************************************************************************/
/* Changed by       : gdcpl (Derek Li) / date: 04APR2024
 * Reason           : add condition footnote(ftn6)
 ******************************************************************************/

%LET mosto_param_class = %scan(&extend_var_disp_12_ezn_52_a, 1, '@');

* Load and extend data;
%load_ads_dat(adlb_view, adsDomain = adlb, adslWhere = &saf_cond.);
%load_ads_dat(adsl_view, adsDomain = adsl, where = &saf_cond.);

%extend_data(
    indat       = adlb_view
  , outdat      = adlb_ext
  , var         = &extend_var_disp_12_ezn_52_a.
  , extend_rule = &extend_rule_disp_12_ezn_52_a_afl.
);

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , subj_var    = USUBJID
  , var         = &extend_var_disp_12_ezn_52_a.
  , extend_rule = &extend_rule_disp_12_ezn_52_a.
);

* Prepare data;
%m_switcher_avisit2(
    indat  = adlb_ext
  , trtvar = &mosto_param_class.
  , byvar  = paramcd
);

DATA adlb_switch;
    SET adlb_ext;
    * Specs: pH, urobilinogen, blood/hemoglobin, total protein, ketone, nitrite, glucose, leukocytes;
    if PARCAT1 = "URINALYSIS"
       AND &lb_avisit_selection. and avisitn ne 900000
       AND paramcd IN (%trim(%quoteWords(&lb_safety_param., quote = Y)))
       and paramcd in ('UPH'   &lb_cat_urine.)  /* Select categorical only */
       and paramcd not in (&liver_param.);
    if paramcd in ('UPH') then do;
        if prxmatch('/\d+\.0/',avalc) then avalc=scan(avalc,1,'.');
    END;
    if avisitn in (&avisit_list.);
    format &mosto_param_class. _trtgrp_ns.;
    *%m_switcher_avisit();
    LABEL avalc=' ';
RUN;


proc sort data= adlb_switch;
    by parcat1 paramcd studyid;
RUN;

data adlb_switch;
    set adlb_switch;
    format _mis_param $500.;
    retain _mis_param;
    by parcat1 paramcd;
    if first.paramcd then _mis_param=strip(vvalue(paramcd))||' is only available for OASIS 1-3.';
    if studyid='21686' then call missing(_mis_param);
RUN;


* Tabelsby;
PROC SORT DATA = adlb_switch OUT = tby (KEEP = parcat1 paramcd _mis_param);
    BY parcat1 paramcd studyid _mis_param;
RUN;

data tby;
    set tby;
    by parcat1 paramcd;
    if last.paramcd;
RUN;

data adlb_switch;
    merge adlb_switch(drop=_mis_param)
          tby;
    by parcat1 paramcd;
RUN;

%set_titles_footnotes(
    tit1 = "Table: Laboratory data: Number of subjects by $parcat1$, $paramcd$ and IA visit by integrated analysis treatment group "
  , tit2 = "<cont>&saf_label"
  , ftn1 = "IA = Integrated Analysis. EoT = End of Treatment."
  , ftn2 = "&foot_w1_12."
  , ftn3 = "&foot_switcher_26_52."
  , ftn4 = "&foot_ia_eot."
  , ftn5 = "Please note that measurements from all scheduled visits in all studies are included. The visit schedule varies among studies, so some visits may only refer to a subset of studies."
  , ftn6 = "$_mis_param$"
);

%freq_tab(
    data          = adlb_switch
  , data_n        = adsl_ext
  , var           = avalc
  , subject       = &subj_var.
  , by            = avisitn
  , data_n_ignore = parcat1 paramcd _mis_param
  , page          = parcat1 paramcd _mis_param
  , total         = NO
  , order         = parcat1 paramcd _mis_param
  , basepct       = n
  , hlabel        = Yes
  , levlabel      = no
  , incln         = yes
  , missing       = NO
  , complete      = min
  , tablesby      = tby
  , freeline      = avisitn
);

%endprog;