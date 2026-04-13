/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_1_7_ice_adds_rsn);
/*
 * Purpose          : Intercurrent events - Permanent discontinuation of randomized treatment: number of subjects by reason (FAS)
 * Programming Spec :
 * Validation Level : 2 - Independent Programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gnrty (Ashu Pandey) / date: 04DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_1_7_ice_adds_rsn.sas (egavb (Reema S Pawar) / date: 21JUN2023)
 ******************************************************************************/

%load_ads_dat(adsl_view, adsDomain = adsl, where = &fas_cond, adslVars  =);
%load_ads_dat(
    adds_view
  , adsDomain = adds
  , adslWhere = &fas_cond
)

%extend_data(indat = adsl_view, outdat = adsl)
%extend_data(indat = adds_view, outdat = adds)

*********************** preparing data ***************************;

DATA ice_ds;
    SET adds;
    WHERE ice01fl = "Y";
RUN;

PROC SQL ;
    CREATE TABLE all AS SELECT usubjid, ICESTWK, ICEREAS, ice01fl,trt01pn,
           CASE WHEN ICESTWK  IN(0 1 )    THEN 'Up to Week 1'
           END AS TIME_n
           FROM ice_ds WHERE ICESTWK  IN(0 1 )
    UNION all
    SELECT usubjid, ICESTWK, ICEREAS, ice01fl,trt01pn,
           CASE WHEN ICESTWK IN(0 1 2 3 4)    THEN 'Up to Week 4'
           END AS TIME_n
           FROM ice_ds WHERE ICESTWK IN(0 1 2 3 4)
    UNION all
    SELECT usubjid, ICESTWK, ICEREAS, ice01fl,trt01pn,
           CASE WHEN ICESTWK IN(0 1 2 3 4 5 6 7 8)   THEN 'Up to Week 8'
           END AS TIME_n
           FROM ice_ds WHERE ICESTWK IN(0 1 2 3 4 5 6 7 8)
    UNION all
    SELECT usubjid, ICESTWK, ICEREAS, ice01fl,trt01pn,
           CASE WHEN ICESTWK IN(0 1 2 3 4 5 6 7 8 9 10 11 12)   THEN 'Up to Week 12'
           END AS TIME_n
           FROM ice_ds WHERE ICESTWK IN(0 1 2 3 4 5 6 7 8 9 10 11 12);
QUIT;

DATA all1;
    SET all;
    FORMAT dur _dstime.;
    dur = input(TIME_n, _dstimen.);
    rsn = 'Any reason';
    IF ICEREAS = "Other" THEN ICEREASn = 99; ELSE ICEREASn= 1;
    LABEL ICEREAS = 'Reasons for permanent discontinuation of randomized treatment';
RUN;


%freq_tab(
    data          = all1
  , data_n        = adsl
  , var           = rsn*dur ICEREAS*dur
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
        IF keyword = 'TOGETHER' THEN value = '';
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
