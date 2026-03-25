/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adds_ise_ice_rsn);
/*
 * Purpose          : Create table: Intercurrent events - Permanent discontinuation of randomized treatment up to Week 12: number of subjects by reason (full analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gltlk (Rui Zeng) / date: 04DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_1_7_ice_adds_rsn.sas (egavb (Reema S Pawar) / date: 21JUN2023)
 ******************************************************************************/

%LET mosto_param_class = &mosto_param_class_eff.;

%load_ads_dat(adsl_view, adsDomain = adsl, where = &fas_cond);
%load_ads_dat(
    adds_view
  , adsDomain = adds
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
    indat       = adds_view
  , outdat      = adds_ext
  , var         = &extend_var_disp_eff.
  , extend_rule = &extend_rule_disp_eff.
);

*********************** preparing data ***************************;

PROC SQL ;
    CREATE TABLE all AS SELECT studyid, usubjid, icestwk, icereas, ice01fl, &mosto_param_class.,
           CASE WHEN ICESTWK  IN (0 1 )    THEN 1
           END AS TIME
           FROM adds_ext WHERE ICESTWK IN (0 1 )
    UNION all
    SELECT studyid, usubjid, icestwk, icereas, ice01fl, &mosto_param_class.,
           CASE WHEN ICESTWK IN (0 1 2 3 4)    THEN 2
           END AS TIME
           FROM adds_ext WHERE ICESTWK IN (0 1 2 3 4)
    UNION all
    SELECT studyid, usubjid, icestwk, icereas, ice01fl, &mosto_param_class.,
           CASE WHEN ICESTWK IN (0 1 2 3 4 5 6 7 8)   THEN 3
           END AS TIME
           FROM adds_ext WHERE ICESTWK IN (0 1 2 3 4 5 6 7 8)
    UNION all
    SELECT studyid, usubjid, icestwk, icereas, ice01fl, &mosto_param_class.,
           CASE WHEN ICESTWK IN (0 1 2 3 4 5 6 7 8 9 10 11 12)   THEN 4
           END AS TIME
           FROM adds_ext WHERE ICESTWK IN (0 1 2 3 4 5 6 7 8 9 10 11 12);
QUIT;

DATA all2;
    SET all;
    FORMAT dur _dstime. rsn $200.;
    dur = time;
    rsn = 'Any reason';
    LABEL icereas = 'Reasons for permanent discontinuation of randomized treatment';
RUN;

%freq_tab(
    data          = all2
  , data_n        = adsl_ext
  , var           = rsn*dur ICEREAS*dur
  , data_n_ignore = ICEREAS
  , basepct       = N_CLASS_MAIN
  , levlabel      = YES
  , misstext      =
  , outdat        = new
  , missing       = NO
  , total         = yes
)

* adjust the layout as TLF spec does;
DATA new;
    SET new;
    IF ICEREAS = "Other" THEN ICEREASn = 99; ELSE ICEREASn= 1;
    IF rsn NE '' THEN    _varl_ = rsn; ELSE _varl_ = ICEREAS ;
    IF _nr_ = 1 THEN ICEREAS = 'Any reason';
    time = put(dur,_dstime.);
    IF _TYPE_ = 2 THEN time = 'Time';
    IF _ord_ = 1 AND _newvar = 2  THEN _newvar = 0 ;
    IF _newvar = 0  THEN time = ' ' ;
    IF _newvar = 1 THEN DELETE ;
    IF _TYPE_ = 2.5 THEN time = 'Time';
    IF _TYPE_ = 2 THEN time = ' ';
    IF _type_ IN( 3 2.5 )THEN _varl_ = '';
    LABEL _varl_ = 'Reasons for permanent discontinuation of randomized treatment';
RUN;

DATA newinp;
    SET newinp;
    IF keyword = "BY" THEN value = " _widownr _nr2_ ICEREASn ICEREAS  _ord_ _newvar _type_ _kind_ _varl_ time";
    IF keyword = "ORDER" THEN value = " _widownr _nr2_ ICEREASn ICEREAS  _ord_ _newvar _type_ _kind_ ";
    IF keyword = 'FREELINE' THEN value = 'ICEREAS';
    IF keyword = 'TOGETHER' THEN value = ' ';
RUN;

%set_titles_footnotes(
    tit1 = "Table: Intercurrent events - Permanent discontinuation of randomized treatment up to Week 12: number of subjects by reason &fas_label."
    , ftn1 = "&foot_placebo_ezn."
    , ftn2 = "Percentages within sub-categories use the total number within this sub-category as denominator. "
);

%mosto_param_from_dat(
    data    = newinp
  , var     = i_call
)

%datalist(&i_call)

/*clean up*/
%endprog;
