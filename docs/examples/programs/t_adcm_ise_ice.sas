/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adcm_ise_ice);
/*
 * Purpose          : Create table: Intercurrent events - Intake of prohibited concomitant medication having impact on efficacy: number of subjects (full analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gltlk (Rui Zeng) / date: 04DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_1_7_ice_adcm_rsn.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/

%LET mosto_param_class = &mosto_param_class_eff.;

%load_ads_dat(adsl_view, adsDomain = adsl, where = &fas_cond);
%load_ads_dat(
    adcm_view
  , adsDomain = adcm
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
    indat       = adcm_view
  , outdat      = adcm_ext
  , var         = &extend_var_disp_eff.
  , extend_rule = &extend_rule_disp_eff.
);

*********************  preparing data for analysis *********************************************;
ODS ESCAPECHAR="^";

PROC SQL ;
    CREATE TABLE all AS SELECT studyid, usubjid, ICEENWK, ICESTWK, CMENRTPT, ice01fl, &mosto_param_class.,
           CASE WHEN ICEENWK >= 1 OR ICEENWK = .       THEN 1
           END AS TIME
           FROM adcm_ext WHERE ICESTWK = 1
    UNION all
    SELECT studyid, usubjid, ICEENWK, ICESTWK, CMENRTPT, ice01fl, &mosto_param_class.,
           CASE WHEN ICEENWK >= 4  OR  ICEENWK = .     THEN 2
           END AS TIME
           FROM adcm_ext WHERE ICESTWK IN(1 2 3 4)
    UNION all
    SELECT studyid, usubjid, ICEENWK, ICESTWK, CMENRTPT, ice01fl, &mosto_param_class.,
           CASE WHEN ICEENWK >= 8  OR  ICEENWK = .     THEN 3
           END AS TIME
           FROM adcm_ext WHERE ICESTWK IN(1 2 3 4 5 6 7 8)
    UNION all
    SELECT studyid, usubjid, ICEENWK, ICESTWK, CMENRTPT, ice01fl, &mosto_param_class.,
           CASE WHEN ICEENWK >= 12   OR  ICEENWK = .   THEN 4
           END AS TIME
           FROM adcm_ext WHERE ICESTWK IN(1 2 3 4 5 6 7 8 9 10 11 12);
QUIT;

DATA final;
    SET all;
    FORMAT time _cmtime.;
    icereas = "Intake of prohibited concomitant medication having impact on efficacy^&super_a.";
RUN;

%set_titles_footnotes(
    tit1 = "Table: Intercurrent events - Intake of prohibited concomitant medication having impact on efficacy up to Week 12: number of subjects &fas_label."
    , ftn1 = "&foot_placebo_ezn."
    , ftn2 = "a Subjects who took more than one prohibited concomitant medication per considered time are counted once."
    , ftn3 = "Any intake of prohibited medication is counted for all the time where it is considered as an intercurrent event, i.e. including the pre-defined washout time period."
    , ftn4 = "Percentages within sub-categories use the total number within this sub-category as denominator. "
);

%freq_tab(
    data          = final
  , data_n        = adsl_ext
  , var           = ICEREAS*time
  , data_n_ignore = ICEREAS
  , basepct       = N_CLASS_MAIN
  , misstext      =
  , outdat        = new
  , missing       = NO
  , complete      = ALL
  , maxlen        = 10
  , split         =
  , total         = yes
)

DATA new;
    length new_time $20;
    SET new;
    new_time = put(time, _cmtime.);
    IF _type_ = 3 THEN _varl_ = '';
/*    IF _newvar = 1 THEN _varl_ = '';*/
    IF _ord_ = 1 and _newvar = 1 THEN do new_time = 'Time' ; seq = 1;end;
    IF _ord_ = 1 and _newvar = 2 THEN do new_time = ''; seq = 1;end; else seq = 3;
    IF _ord_ = 1 and _newvar = 1 THEN  _varl_ = '';
IF _ord_ = 1 and _newvar = 2 THEN  _varl_ =  "Intake of prohibited concomitant medication having impact on efficacy^&super_a." ;
RUN;

DATA newinp;
    SET newinp;
    IF keyword = "BY" THEN value = " _widownr _nr2_ seq ICEREAS  _newvar _ord_  _type_ _kind_ _varl_ time new_time";
    IF keyword = "ORDER" THEN value = " _widownr _nr2_ seq ICEREAS  _newvar _ord_  _type_ _kind_  time";
    IF keyword = 'FREELINE' THEN value = 'ICEREAS';
    IF keyword = 'TOGETHER' THEN value = '_newvar';
RUN;

%mosto_param_from_dat(
    data    = newinp
  , var     = i_call
)

%datalist(&i_call)

/*clean up*/
%endprog;