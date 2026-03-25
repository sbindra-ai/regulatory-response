/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adex_ise_ice_rsn);
/*
 * Purpose          : Create table: Intercurrent events - Temporary treatment interruption up to Week 12: number of subjects by reason (full analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gltlk (Rui Zeng) / date: 24JAN2024
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_1_7_ice_adex_rsn.sas (egavb (Reema S Pawar) / date: 21JUN2023)
 ******************************************************************************/

%LET mosto_param_class = &mosto_param_class_eff.;

%load_ads_dat(adsl_view, adsDomain = adsl, where = &fas_cond);
%load_ads_dat(
    adex_view
  , adsDomain = adex
  , where     = ice01fl = "Y"
  , adslWhere = &fas_cond
)

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_eff.
  , extend_rule = &extend_rule_disp_eff.
);

%extend_data(
    indat       = adex_view
  , outdat      = adex_ext
  , var         = &extend_var_disp_eff.
  , extend_rule = &extend_rule_disp_eff.
);

****************  preparing data for analysis  ******************;
ODS ESCAPECHAR="^";

DATA ice_adex (KEEP=studyid usubjid icereas ice01fl &mosto_param_class. aphase paramcd time rsn);
    SET adex_ext;
    FORMAT time _extime. rsn $200.;
    rsn = 'Any interruption';
    IF PARAMCD = 'TRTINW1' THEN TIME = 1;
    IF PARAMCD ='TRTINW4' THEN TIME = 2;
    IF PARAMCD ='TRTINW8' THEN TIME = 3;
    IF PARAMCD ='TRTINW12' THEN TIME = 4;
    LABEL ICEREAS  = "Reasons for temporary treatment interruption^&super_a.";
    WHERE ICEREAS NOT IN ('< 5/7 Days' '< 80% Compliance' '< 80% Compliance and < 5/7 Days');  *consider only reasons for temporary treatment interruption which is collected in EC.ECADJ;
RUN;

%freq_tab(
    data          = ice_adex
  , data_n        = adsl_ext
  , var           = rsn*time ICEREAS*time
  , data_n_ignore = ICEREAS
  , basepct       = N_CLASS_MAIN
  , levlabel      = YES
  , misstext      =
  , outdat        = new
  , missing       = NO
  , total         = yes
)

DATA new;
    SET new;
    IF ICEREAS = "Other" THEN ICEREASn = 99; ELSE ICEREASn= 1;
    IF rsn NE '' THEN    _varl_ = rsn; ELSE _varl_ = ICEREAS ;
    IF _nr_ = 1 THEN ICEREAS = 'Any interruption';
    duration = put(time,_extime.);
    if _TYPE_ = 2.5 then duration = 'Time';
    if _TYPE_ = 2 and _newvar = 2 then duration = '';
    if _TYPE_ = 2 and _newvar = 1 then duration = 'Time';
    IF _type_ in(3 2.5 ) THEN _varl_ = '';
    IF _type_ = 2 and duration = 'Time' THEN delete;
    LABEL _varl_ = "Reasons for temporary treatment interruption^&super_a.";
RUN;

DATA newinp;
    SET newinp;
    IF keyword = "BY" THEN value = " _widownr _nr2_ ICEREASn ICEREAS  _ord_ _newvar _type_ _kind_ _varl_ time duration";
    IF keyword = "ORDER" THEN value = " _widownr _nr2_ ICEREASn ICEREAS  _ord_ _newvar _type_ _kind_ time";
    IF keyword = 'FREELINE' THEN value = 'ICEREAS';
    IF keyword = 'TOGETHER' THEN value = '_newvar';
RUN;

%set_titles_footnotes(
    tit1 = "Table: Intercurrent events - Temporary treatment interruption up to Week 12: number of subjects by reason &fas_label."
    , ftn1 = "&foot_placebo_ezn."
    , ftn2 = "A participant could have single day treatment interruptions without reason."
    , ftn3 = "a There can be several reasons for temporary treatment interruptions per subject and considered time. Therefore, one subject can be counted in more than one reason category."
    , ftn4 = "The reason for a temporary treatment interruption is only collected if a subject interrupted treatment for more than 2 consecutive days."
    , ftn5 = "Percentages within sub-categories use the total number within this sub-category as denominator. "
);

%mosto_param_from_dat(
    data = newinp
  , var  = i_call
)

%datalist(&i_call)

/*clean up*/
%endprog;