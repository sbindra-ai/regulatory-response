/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_1_7_ice_adex_rsn);
/*
 * Purpose          : Intercurrent events - Temporary treatment interruption: number of subjects by reason (FAS)
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gnrty (Ashu Pandey) / date: 12DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_1_7_ice_adex_rsn.sas (egavb (Reema S Pawar) / date: 21JUN2023)
 ******************************************************************************/
%load_ads_dat(adsl_view, adsDomain = adsl, where = &fas_cond, adslVars  =);
%load_ads_dat(
    adex_view
  , adsDomain = adex
  , where     = ice01fl = "Y"
  , adslWhere = &fas_cond
)

%extend_data(indat = adsl_view, outdat = adsl)
%extend_data(indat = adex_view, outdat = adex)

****************  preparing data for analysis  ******************;
ODS ESCAPECHAR="^";

DATA ice_adex (KEEP=usubjid icereas ice01fl trt01pn APHASE PARAMCD TIME rsn);
    SET adex;FORMAT time _extime. rsn $200.;
    rsn = 'Any interruption';
IF PARAMCD = 'TRTINW1' THEN TIME = 1;
IF PARAMCD ='TRTINW4' THEN TIME = 2;
IF PARAMCD ='TRTINW8' THEN TIME = 3;
IF PARAMCD ='TRTINW12' THEN TIME = 4;
LABEL ICEREAS  = "Reasons for temporary treatment interruption^&super_a.";
WHERE ICEREAS NOT IN ('< 5/7 Days' '< 80% Compliance' '< 80% Compliance and < 5/7 Days');
RUN;


%freq_tab(
    data          = ice_adex
  , data_n        = adsl
  , var           = rsn*time ICEREAS*time
  , subject       = &subj_var.
  , data_n_ignore = ICEREAS
  , class         = &TREAT_ARM_P
  , basepct       = N_CLASS_MAIN
  , levlabel      = YES
  , misstext      =
  , outdat        = new
  , missing       = NO
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

%MTITLE;

%mosto_param_from_dat(
    data    = newinp
  , var     = i_call
  , keyword = keyword
  , value   = value
)

%datalist(&i_call)

/*clean up*/
%endprog
