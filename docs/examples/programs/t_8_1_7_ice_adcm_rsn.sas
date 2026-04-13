/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_1_7_ice_adcm_rsn);
/*
 * Purpose          : Intercurrent events: Intake of prohibited concomitant medication having impact on efficacy
 * Programming Spec :
 * Validation Level : 2 - Independent Programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gnrty (Ashu Pandey) / date: 04DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_1_7_ice_adcm_rsn.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/
%load_ads_dat(adsl_view, adsDomain = adsl, where = &fas_cond, adslVars  =);
%load_ads_dat(
    adcm_view
  , adsDomain = adcm
  , where     = ice01fl = "Y"
  , adslWhere = &fas_cond
)

%extend_data(indat = adsl_view, outdat = adsl)
%extend_data(indat = adcm_view, outdat = adcm)

*********************  preparing data for analysis *********************************************;

data dur_1 dur_4 dur_8 dur_12;
    set adcm;
    if ICESTWK = 1 and (ICEENWK ge 1  or ICEENWK eq .) then output dur_1;
    if ICESTWK ne . and ICESTWK ge 1 and ICESTWK le 4 and (ICEENWK ge 4  or ICEENWK eq .) then output dur_4;
    if ICESTWK ne . and ICESTWK ge 1 and ICESTWK le 8 and (ICEENWK ge 8  or ICEENWK eq .) then output dur_8;
    if ICESTWK ne . and ICESTWK ge 1 and ICESTWK le 12 and  (ICEENWK ge 12  or ICEENWK eq .) then output dur_12;
RUN;


*********************  applying super script *********************************************;

ODS ESCAPECHAR="^";

data final;
    set dur_1(in=a) dur_4(in=b) dur_8(in=c) dur_12(in=d);
    if d then time = 'During Week 12';
    else if a then time = 'During Week 1';
    else if b then time = 'During Week 4';
    else if c then time = 'During Week 8';
    FORMAT timen _cmtime.;
    timen = input(time, _cmtimen. );
    icereas = "Intake of prohibited concomitant medication having impact on efficacy^&super_a.";
    keep usubjid  ICEENWK  ICESTWK  CMENRTPT  ice01fl trt01pn time timen icereas;
RUN;

%freq_tab(
    data          = final
  , data_n        = adsl
  , var           = ICEREAS*timen
  , subject       = &subj_var.
  , data_n_ignore = ICEREAS
  , class         = &TREAT_ARM_P
  , basepct       = N_CLASS_MAIN
  , misstext      =
  , outdat        = new
  , missing       = NO
  , complete      = ALL
  , maxlen        = 10
  , split         =
)

DATA new;
    length new_time $20;
    SET new;
    new_time = put(timen, _cmtime.);
    IF _type_ = 3 THEN _varl_ = '';
/*    IF _newvar = 1 THEN _varl_ = '';*/
    IF _ord_ = 1 and _newvar = 1 THEN do new_time = 'Time' ; seq = 1;end;
    IF _ord_ = 1 and _newvar = 2 THEN do new_time = ''; seq = 1;end; else seq = 3;
    IF _ord_ = 1 and _newvar = 1 THEN  _varl_ = '';
IF _ord_ = 1 and _newvar = 2 THEN  _varl_ =  "Intake of prohibited concomitant medication having impact on efficacy^&super_a." ;
RUN;

DATA newinp;
    SET newinp;
    IF keyword = "BY" THEN value = " _widownr _nr2_ seq ICEREAS  _newvar _ord_  _type_ _kind_ _varl_ timen new_time";
    IF keyword = "ORDER" THEN value = " _widownr _nr2_ seq ICEREAS  _newvar _ord_  _type_ _kind_  timen";
    IF keyword = 'FREELINE' THEN value = 'ICEREAS';
    IF keyword = 'TOGETHER' THEN value = '_newvar';
RUN;

%MTITLE;

%mosto_param_from_dat(
    data    = newinp
  , var     = i_call
  , keyword = keyword
  , value   = value
)

%datalist(&i_call)

/*clean up*/
%endprog;