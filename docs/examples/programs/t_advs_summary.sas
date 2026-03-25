/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
    %iniprog(name = t_advs_summary);
/*
 * Purpose          : Vital signs: summary statistics and change from baseline by integrated analysis treatment group - {parameter name, unit} (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : ereiu (Katharina Meier) / date: 12DEC2023
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : gdcpl (Derek Li) / date: 13FEB2024
 * Reason           : remove ANL01FL filter condition
 ******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 15FEB2024
 * Reason           : Use &foot_w1_12., "&foot_ia_eot.", &foot_switcher_26_52.
 ******************************************************************************/
/* Changed by       : gdcpl (Derek Li) / date: 26MAR2024
 * Reason           : set the value of together to NULL
 ******************************************************************************/

%LET mosto_param_class = %scan(&extend_var_disp_12_ezn_52_a_nsa, 1, '@');

* Load and extend data;
%load_ads_dat(advs, adsDomain = advs, where = avisitn>=5, adslWhere = &saf_cond.);

%extend_data(
    indat       = advs
  , outdat      = advs_ext
  , var         = &extend_var_disp_12_ezn_52_a_nsa.
  , extend_rule = &extend_rule_disp_12_ezn_52_a_afl.
);

* Prepare data;
%m_switcher_avisit2(
    indat  = advs_ext
  , trtvar = &mosto_param_class.
  , byvar  = paramcd
);

DATA advs_ext ;
   SET advs_ext;

   * Round AVAL BASE and CHG;
   FORMAT aval 6./* &mosto_param_class. _trtgrp_nsa.*/;

   *%m_switcher_avisit();

   * Vital signs (pulse rate, systolic blood pressure and diastolic blood pressure) will be summarized based on
     summary statistics by integrated analysis treatment group ;
         if paramcd = 'HR'    then _paramn = 1;
    else if paramcd = 'SYSBP' then _paramn = 2;
    else if paramcd = 'DIABP' then _paramn = 3;
    else delete;
RUN;

proc sort data= advs_ext;
    by _paramn paramcd studyid;
RUN;

data advs_ext;
    set advs_ext;
    format _mis_param $500.;
    retain _mis_param;
    by _paramn paramcd;
    if first.paramcd then _mis_param=strip(vvalue(paramcd))||' is only available for OASIS 1-3.';
    if studyid='21686' then call missing(_mis_param);
RUN;

* TABLESBY;
PROC SORT DATA = advs_ext OUT = tby(KEEP =_mis_param  _paramn  paramcd);
    BY _paramn paramcd studyid _mis_param;
RUN;

data tby;
    set tby;
    by _paramn paramcd;
    if last.paramcd;
RUN;

data advs_ext;
    merge advs_ext(drop=_mis_param) tby;
    by _paramn paramcd;
RUN;

* Output;
%set_titles_footnotes(
    tit1 = "Table: Vital signs: summary statistics and change from baseline by IA visit and by integrated analysis treatment group"
  , tit2 = "<cont>- $paramcd$ &saf_label."
  , ftn1 = "IA= Integrated Analysis. SD = Standard Deviation. EoT= End of Treatment."
  , ftn2 = "&foot_w1_12."
  , ftn3 = "&foot_switcher_26_52."
  , ftn4 = "&foot_ia_eot."
  , ftn5 = "Please note that measurements from all scheduled visits in all studies are included. The visit schedule varies among studies, so some visits may only refer to a subset of studies. Change from baseline is only calculated for participants who have measurements at baseline as well as the respective visit."
  , ftn6 = "$_mis_param$"
);

%desc_tab(
    data         = advs_ext
  , var          = aval
  , page         = _paramn paramcd _mis_param
  , order        = _paramn paramcd _mis_param
  , class        = avisitn
  , class_order  = avisitn
  , vlabel       = no
  , baseline     = ablfl='Y'
  , compare_var  = chg
  , baseline_pre = avisitn <10
  , time         = &mosto_param_class.
  , tablesby     = tby
  , visittext    = visit
  , maxlen       = 20
  , hsplit       = '#'
  , together     =
);

%endprog(cleanWork = Y);