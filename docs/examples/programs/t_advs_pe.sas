/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
%iniprog(name = t_advs_pe)
;
/*
 * Purpose          : Physical examination: summary statistics and change from baseline by integrated analysis treatment group - {parameter name, unit} (safety analysis set)
 *                    Physical examination parameter: Weight, hip and waist circumference
 *                    (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : ereiu (Katharina Meier) / date: 14DEC2023
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : gdcpl (Derek Li) / date: 15FEB2024
 * Reason           : remove anl01fl=Y filter condition in %load_ads_dat
 ******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 15FEB2024
 * Reason           : # Use &foot_w1_12., "&foot_ia_eot.", &foot_switcher_26_52.
 *                    # Use &extend_var_disp_12_ezn_52_a_nsa
 ******************************************************************************/
/* Changed by       : gdcpl (Derek Li) / date: 26MAR2024
 * Reason           : set together to NULL
 ******************************************************************************/

%LET mosto_param_class = %scan(&extend_var_disp_12_ezn_52_a_nsa, 1, '@');

* Load and extend data;
%load_ads_dat(
    advs
  , adsDomain = advs
  , where     = avisitn >= 5 AND paramcd IN ('WEIGHT' 'HIPCIR' 'WAISTHIP' 'WSTCIR')
  , adslWhere = &saf_cond.
)
;
%load_ads_dat(adsl, adsDomain = adsl, where = &saf_cond.)
;

%extend_data(
    indat       = advs
  , outdat      = advs_ext
  , subj_var    = USUBJID
  , var         = &extend_var_disp_12_ezn_52_a_nsa.
  , extend_rule = &extend_rule_disp_12_ezn_52_a_afl.
)
;

%extend_data(
    indat       = adsl
  , outdat      = adsl_ext
  , subj_var    = USUBJID
  , var         = &extend_var_disp_12_ezn_52_a_nsa.
  , extend_rule = &extend_rule_disp_12_ezn_52_a.
)
;

* Prepare data;
%m_switcher_avisit2(
    indat  = advs_ext
  , trtvar = &mosto_param_class.
  , byvar  = paramcd
)
;

DATA advs_switcher;
    SET advs_ext;

    * Round AVAL BASE and CHG;
    FORMAT aval chg 6.1 /*&mosto_param_class. _trtgrp_nsa.*/;

    * y label should be the unit;
    length unit $20.;
    unit = strip(tranwrd(scan(vvalue(paramcd), 2, "("), ")", ""));

    * Vital signs parameter: heart rate, systolic blood pressure and diastolic blood pressure;
    if paramcd = 'WEIGHT'   then _paramn = 1;
    else if paramcd = 'HIPCIR'   then _paramn = 2;
    else if paramcd = 'WAISTHIP' then _paramn = 3;
    else if paramcd = 'WSTCIR'   then _paramn = 4;
    else delete;
    if _paramn = 3 then roundf_c=0.001;
    else roundf_c=0.1;
RUN;

proc sort data= advs_switcher;
    by _paramn paramcd studyid;
RUN;

data advs_switcher;
    set advs_switcher;
    format _mis_param $500.;
    retain _mis_param;
    by _paramn paramcd;
    if first.paramcd then _mis_param=strip(vvalue(paramcd))||' is only available for OASIS 1-3.';
    if studyid='21686' then call missing(_mis_param);
RUN;

* TBY;
proc sort data = advs_switcher  out = tby(keep =_mis_param _paramn paramcd);
    by _paramn paramcd studyid _mis_param ;
run;

data tby;
    set tby;
    by _paramn paramcd;
    if last.paramcd;
RUN;

data advs_switcher;
    merge advs_switcher(drop=_mis_param) tby;
    by _paramn paramcd;
RUN;

* Output;
%set_titles_footnotes(
    tit1 = "Table: $paramcd$: summary statistics and change from baseline by IA visit and by integrated analysis treatment group &saf_label."
  , ftn1 = "IA= Integrated Analysis. SD = Standard Deviation. EoT= End of Treatment."
  , ftn2 = "&foot_w1_12."
  , ftn3 = "&foot_switcher_26_52."
  , ftn4 = "&foot_ia_eot."
  , ftn5 = "Please note that measurements from all scheduled visits in all studies are included. The visit schedule varies among studies, so some visits may only refer to a subset of studies. Change from baseline is only calculated for participants who have measurements at baseline as well as the respective visit."
  , ftn6 = "$_mis_param$"
)
;

%desc_tab(
    data         = advs_switcher
  , var          = aval
  , stat         = n mean std min median max
  , page         = _paramn paramcd _mis_param
  , order        = _paramn paramcd _mis_param
  , class        = avisitn
  , class_order  = avisitn
  , round_factor = roundf_c
  , vlabel       = no
  , baseline     = ablfl = "Y"
  , compare_var  = chg
  , time         = &mosto_param_class
  , visittext    = visit
  , baselinetext =
  , subject      = usubjid
  , tablesby     = tby
  , optimal      = yes
  , maxlen       = 30
  , together     =
)
;

%endprog()
;
