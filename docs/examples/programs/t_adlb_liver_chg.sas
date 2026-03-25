/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
    %iniprog(name = t_adlb_liver_chg);
/*
 * Purpose          : Laboratory data: summary statistics and change from baseline by IA visit and by integrated analysis treatment group  {liver parameters} (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gdcpl (Derek Li) / date: 07JUL2023
 *******************************************************************************/
/* Changed by       : gdcpl (Derek Li) / date: 19OCT2023
 * Reason           : update per t_adlb_chg_gcat
 ******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 07DEC2023
 * Reason           : # Copy code from program t_adlb_chg_gcat
 *                    # Restrict to paramcd in (&liver_param)
 *                    # Update title
 *                    # Use &lb_avisit_selection.
 *                    # Remove SLAT use round_factor = 0.1
 *                    # Use %m_switcher_avisit2
 ******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 15FEB2024
 * Reason           : Use &foot_w1_12., "&foot_ia_eot." and &foot_switcher_26_52., &foot_lb_limit_detection.
 ******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 01MAR2024
 * Reason           : # Update footnote
 *                    # Use &extend_var_disp_12_ezn_52_a_nsa
 ******************************************************************************/
/* Changed by       : gdcpl (Derek Li) / date: 04APR2024
 * Reason           : set the value of together to null
 ******************************************************************************/


%LET mosto_param_class = %scan(&extend_var_disp_12_ezn_52_a_nsa., 1, '@');
%let params            = parcat1 paramcd paramn;

* Load and extend data;
%load_ads_dat(adlb_view, adsDomain = adlb, adslWhere = &saf_cond.);
%load_ads_dat(adsl_view, adsDomain = adsl, where = &saf_cond.);

%extend_data(
    indat       = adlb_view
  , outdat      = adlb_ext
  , var         = &extend_var_disp_12_ezn_52_a_nsa.
  , extend_rule = &extend_rule_disp_12_ezn_52_a_afl.
);

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , subj_var    = USUBJID
  , var         = &extend_var_disp_12_ezn_52_a_nsa.
  , extend_rule = &extend_rule_disp_12_ezn_52_a.
);

* Prepare data;
%m_switcher_avisit2(
    indat  = adlb_ext
  , trtvar = &mosto_param_class.
  , byvar  = paramcd
);

**get rounding factor from SLAT;
PROC SORT DATA = g_data.slat(KEEP = test roundf_c) OUT = rounding(RENAME = (test = paramcd)) NODUPKEY;
    BY test roundf_c;
RUN;
PROC SORT DATA = adlb_ext;
    BY paramcd;
RUN;

DATA adlb_ext;
    MERGE adlb_ext(IN = a)
          rounding;
    BY paramcd;
    IF a;

    IF missing(roundf_c) THEN roundf_c = 0.01 ;

RUN;

DATA adlb_switch;
    SET adlb_ext;

    * Select parameter;
    if     paramcd in (&liver_param.) /* liver parameter */;

    * Further exclusions;
    IF missing(paramtyp) AND /*NOT missing(aval) AND*/ NOT missing(paramcd);

    * Specs ftn: Please note that measurements from all scheduled visits in all studies are included. ;
    if &lb_avisit_selection. and avisitn ne 900000 and lbstat ne "NOT DONE";
    if avisitn in (&avisit_list.);


RUN;



proc sort data= adlb_switch;
    by &params. studyid;
RUN;

data adlb_switch;
    set adlb_switch;
    format _mis_param $500.;
    retain _mis_param;
    by &params;
    if first.paramn then _mis_param=strip(vvalue(paramn))||' is only available for OASIS 1-3.';
    if studyid='21686' then call missing(_mis_param);
RUN;


* TABLESBY;
PROC SORT DATA = adlb_switch OUT = tby(KEEP = &params. _mis_param);
    BY &params. studyid _mis_param ;
RUN;

data tby;
    set tby;
    by &params.;
    if last.paramn;
RUN;

proc sort data = adlb_switch;
    by &params.;
run;

data adlb_switch;
    merge adlb_switch(drop=_mis_param)
          tby;
    by &params.;
RUN;

%set_titles_footnotes(
    tit1 = "Table: Hepatic safety laboratory data: summary statistics and change from baseline by IA visit and by integrated analysis treatment group - $parcat1$,"
  , tit2 = "<cont>$paramn$ &saf_label."
  , ftn1 = "IA = Integrated Analysis. SD = Standard Deviation. EoT = End of Treatment."
  , ftn2 = "&foot_w1_12."
  , ftn3 = "&foot_switcher_26_52."
  , ftn4 = "&foot_ia_eot."
  , ftn5 = "Please note that measurements from all scheduled visits in all studies are included. The visit schedule varies among studies, so some visits may only refer to a subset of studies. Change from baseline is only calculated for participants who have measurements at baseline as well as the respective visit."
  , ftn6 = "&foot_lb_limit_detection."
  , ftn7 = "$_mis_param$"
);

%desc_tab(
    data          = adlb_switch
  , var           = aval
  , page          = &params. _mis_param
  , data_n_ignore = &params. _mis_param
  , order         = &params. _mis_param
  , class         = avisitn
  , class_order   = avisitn
  , round_factor  = roundf_c
  , vlabel        = NO
  , visittext    = visit
  , baseline      = ablfl = 'Y'
  , compare_var   = chg
  , time          = &mosto_param_class.
  , subject       = &subj_var
  , tablesby      = tby
  , optimal       = YES
  , together      =
);

%symdel params;
%endprog();