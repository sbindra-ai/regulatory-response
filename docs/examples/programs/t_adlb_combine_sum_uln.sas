/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
    %iniprog(name = t_adlb_combine_sum_uln);
/*
 * Purpose          : Number of subject by combined hepatic summary relative to UNL
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
 *                    # Add footnote
 *                    # Use splited treatment label
 *                    # Use %m_switcher_avisit2
 ******************************************************************************/
/* Changed by       : gdcpl (Derek Li) / date: 05DEC2023
 * Reason           : add codes to keep only one record for each subject, @Katharina, if you think
 *                    it is ok, please remove my name here
 ******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 08DEC2023
 * Reason           : # Update %m_switcher_avisit2
 *                    # Use &post_baseline_cond.
 ******************************************************************************/
/* Changed by       : gdcpl (Derek Li) / date: 14FEB2024
 * Reason           : use avisitn>5 to replace &postbaseline_cond.
 ******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 15FEB2024
 * Reason           : Update footnote
 ******************************************************************************/
/* Changed by       : gdcpl (Derek Li) / date: 16FEB2024
 * Reason           : update footnote per TLF spec v1.4
 ******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 19FEB2024
 * Reason           :  Comment insert options to avoid pagebreak due to week 1-26 display
 ******************************************************************************/
/* Changed by       : gdcpl (Derek Li) / date: 22MAR2024
 * Reason           : add footnote for INR
 ******************************************************************************/


%LET mosto_param_class = %scan(&extend_var_disp_12_ezn_52_a, 1, '@');

* Load and extend data;
%load_ads_dat(adlb_view, adsDomain = adlb , where = 95001000 le paramn le 95008000 and avisitn>5, adslWhere = &saf_cond.); * Select CCRIT 1 to 8;
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
    Attrib avisit LABEL = 'Time interval' length = $200.;
    avisit = "At any time post-baseline";

    FORMAT critflall $x_ny.;
    attrib critall format = $200. label = 'Category';

    critall   = put(paramcd,$x_lbpar.);

    if paramcd = "CCRIT7" then critall = strip(critall) || " (a)";
    if paramcd = "CCRIT4" then critall = strip(critall) || "*";
    critflall = avalc;
RUN;

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
    tit1 = "Table: Number of subjects by combined hepatic safety laboratory categories relative to ULN &saf_label"
  , ftn1 = "n = number of subjects with parameter assessment done at respective time point."
  , ftn2 = "(a) as collected on the CRF page 'Clinical Signs and Symptoms with elevated liver enzymes'."
  , ftn3 = "At any time post-baseline for OASIS 3, the event onset is up to day 182 (inclusive) for EZN 120 mg (week 1-26)."
  , ftn4 = "Unscheduled visits were included in the analysis."
  , ftn5 = " ULN = Upper Limit of Normal."
  , ftn6 = "AST = Aspartate Aminotransferase, ALT = Alanine Transferase, ALP = Alkaline Phosphatase, INR = International Normalized Ratio."
  , ftn7 = '*INR is only available for OASIS 1-3.'
);

/*
, ftn2 = "Post-baseline is defined for EZN 120 mg (week 1-12) and Placebo (week 1-12) as following: All measurements taken at or after the date of first study drug intake are considered with the following exceptions: For OASIS 1-2 measurements during"
, ftn3 = "<cont> the open-label phase are excluded. For OASIS 3 measurements after the date of first study drug intake + 83 days are excluded. For SWITCH-1, all measurements up to and including the last observation are included."
, ftn4 = "For EZN 120 mg (week 1-52), post-baseline is defined as all measurements taken at or after the first study drug intake of elinzanetant until the last observation."
*/
/*%LET MOSTOCALCPERCWIDTH=NO;*/
/**/
/*%insertoptionrtf(namevar = avisit,  width = 91.0pt,  keep = n, overwrite = no);*/
/*%insertoptionrtf(namevar = critall, width = 308.0pt, keep = n, overwrite = no);*/
/*%insertoptionrtf(namevar = _varl_,  width = 21.0pt,  keep = n, overwrite = no);*/
/*%insertoptionrtf(namevar = _cptog1, width = 55.0pt,  keep = n, overwrite = no);*/
/*%insertoptionrtf(namevar = _cptog2, width = 55.0pt,  keep = n, overwrite = no);*/
/*%insertoptionrtf(namevar = _cptog3, width = 63.0pt,  keep = n, overwrite = no);*/

%freq_tab(
    data     = adlb_switch
  , data_n   = adsl_ext
  , var      = critflall
  , subject  = usubjid
  , by       = avisit paramn critall
  , total    = no
  , order    = paramn
  , basepct  = n
  , hlabel   = yes
  , complete = all
  , maxlen   = 15
  , bylen    = 20
  , hsplit   = '#'
);

/*%LET MOSTOCALCPERCWIDTH=optimal;*/

%endprog();