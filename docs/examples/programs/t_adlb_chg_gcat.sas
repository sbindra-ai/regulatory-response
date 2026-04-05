/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
    %iniprog(name = t_adlb_chg_gcat);
/*
 * Purpose          : Laboratory data: summary statistics and change from baseline by IA visit and integrated analysis treatment group - HEMATOLOGY {parameter name, unit} (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gdcpl (Derek Li) / date: 19OCT2023
 *******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 07DEC2023
 * Reason           : # Update header
 *                    # Simplify code (use &extend_rule_disp_12_ezn_52_a_afl., ...)
 *                    # Use &lb_safety_param. and &lb_avisit_selection.
 *                    # Add _lborder = 6
 *                    # Remove SLAT use round_factor = 0.1
 *                    # Use %m_switcher_avisit2
 ******************************************************************************/
/* Changed by       : gdcpl (Derek Li) / date: 14FEB2024
 * Reason           : change author
 ******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 16FEB2024
 * Reason           : # Use &foot_w1_12., "&foot_ia_eot.", &foot_switcher_26_52., &foot_lb_limit_detection.
 *                    # Use &extend_var_disp_12_ezn_52_a_nsa#
 *                    # Add EoT definition to footnote
 ******************************************************************************/
/* Changed by       : gdcpl (Derek Li) / date: 15MAR2024
 * Reason           : add footnote Sex Hormone Binding Globulin value of 9999 is due to the result being unmeasurable.
 ******************************************************************************/
/* Changed by       : evmqf (Rowland Hale) / date: 18MAR2024
 * Reason           : Changed foot_sexbh_explanation to foot_bap_ul_explanation
 ******************************************************************************/
/* Changed by       : gdcpl (Derek Li) / date: 04APR2024
 * Reason           : add condition footnote(ftn8)
 ******************************************************************************/

%LET mosto_param_class = %scan(&extend_var_disp_12_ezn_52_a_nsa, 1, '@');
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
    if     paramcd in (%trim(%quoteWords(&lb_safety_param., quote = Y))) /* Safety parameter        */
       and paramcd not in (&liver_param. &lb_cat_urine.)                 /* Exclude liver and categorical parameter */
       and parcat1 ne "URINALYLSIS"                                      /* Exclude categorical     */
    ;
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

data tby;
    set tby;
    loop = _n_;
RUN;

* Merge loop to adlb_switch;
proc sort data = adlb_switch; by &params.; run;

data adlb_switch;
    merge adlb_switch(drop=_mis_param)
          tby;
    by &params.;
RUN;

%let params = &params. _mis_param loop;

%macro _tab;

    proc sql noprint;
        select min(loop) into : min from tby;
        select max(loop) into : max from tby;
    QUIT;

    %do i = &min. %to &max.;

        %set_titles_footnotes(
            tit1 = "Table: Laboratory data: summary statistics and change from baseline by IA visit and by integrated analysis treatment group - $parcat1$,"
          , tit2 = "<cont>$paramn$ &saf_label."
          , ftn1 = "IA= Integrated Analysis. SD = Standard Deviation. EoT = End of Treatment."
          , ftn2 = "&foot_w1_12."
          , ftn3 = "&foot_switcher_26_52."
          , ftn4 = "&foot_ia_eot."
          , ftn5 = "Please note that measurements from all scheduled visits in all studies are included. The visit schedule varies among studies, so some visits may only refer to a subset of studies. Change from baseline is only calculated for participants who have measurements at baseline as well as the respective visit."
          , ftn6 = "&foot_lb_limit_detection."
          %if &i. = 4 /* BAP_UL */ %then %do;
              , ftn7 = "&foot_bap_ul_explanation."
          %END;
          %if &i. = 23 /* SEXBH */ %then %do;
            , ftn7 = "Sex Hormone Binding Globulin value of 9999 is due to the result being unmeasurable."
          %END;
          , ftn8 = "$_mis_param$"
        );

        %desc_tab(
            data          = adlb_switch(where = (loop = &i.))
          , var           = aval
          , page          = &params.
          , data_n_ignore = &params.
          , order         = &params.
          , class         = avisitn
          , class_order   = avisitn
          , round_factor  = roundf_c
          , vlabel        = NO
          , visittext    = visit
          , baseline      = ablfl = 'Y'
          , compare_var   = chg
          , time          = &mosto_param_class.
          , subject       = &subj_var.
          , tablesby      = tby(where = (loop = &i.))
          , optimal       = YES
          , together      =
        );
    %end;

%mend _tab;
%_tab;

%symdel params;
%endprog();