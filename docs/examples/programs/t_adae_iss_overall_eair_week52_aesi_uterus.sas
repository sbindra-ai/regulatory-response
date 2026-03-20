/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adae_iss_overall_eair_week52_aesi_uterus);
/*
 * Purpose          : Treatment-emergent adverse events of special interest (post-menopausal uterine bleeding) up to week 52:
 *                    overview of number of subjects and study size and exposure-adjusted incidence rate by integrated analysis treatment group (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : erjli (Yosia Hadisusanto) / date: 15NOV2023
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : erjli (Yosia Hadisusanto) / date: 04DEC2023
 * Reason           : Update
 ******************************************************************************/
/* Changed by       : erjli (Yosia Hadisusanto) / date: 13DEC2023
 * Reason           : Add where= trtemfl = 'Y'
 ******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 26JAN2024
 * Reason           : Remove line "Any treatment-emergent event" as same as "Any event" (based on CRM comment)
 ******************************************************************************/
/* Changed by       : erjli (Yosia Hadisusanto) / date: 14FEB2024
 * Reason           : Update header
 ******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 19FEB2024
 * Reason           : Add &saf_label. to title
 ******************************************************************************/
/* Changed by       : erjli (Yosia Hadisusanto) / date: 18MAR2024
 * Reason           : Delete footnote
 ******************************************************************************/

%LET mosto_param_class = %scan(&extend_var_disp_52_nt_a., 1, '@');

%load_ads_dat(adsl_view, adsDomain = adsl, where     = &saf_cond.)
%load_ads_dat(adae_view, adsDomain = adae, adslWhere = &saf_cond., where= trtemfl = 'Y')
%load_ads_dat(admh_view, adsDomain = admh, adslwhere = &saf_cond.);

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_52_nt_a.
  , extend_rule = &extend_rule_disp_52_nt_a.
)

%LET ezn_pure_cond      = (trt01an in (53));
%LET ezn_switcher_cond  = (trt02an in (53) and aphase = 'Week 13-52');
%LET pla_pure_cond      = (trt01an in (9901) and missing(trt02an));
%LET pla_switcher_cond  = (trt02an in (53) and aphase = 'Week 1-12');

%extend_data(
    indat       = adae_view
  , outdat      = adae_ext
  , var         = &extend_var_disp_52_nt_a.
  , extend_rule = &ezn_pure_cond. OR &ezn_switcher_cond. # &trt_ezn_52.
                @ &pla_pure_cond. OR &pla_switcher_cond. # &trt_pla_52.
)

%extend_data(
    indat       = admh_view
  , outdat      = admh_ext
  , var         = &extend_var_disp_52_nt_a.
  , extend_rule = &extend_rule_disp_52_nt_a.
);

%m_add_time_window(indat = adsl_ext, outdat = adsl_ext);

DATA hysterectomy(KEEP=&subj_var.);
    SET admh_ext(WHERE=(mhdecod in ('Hysterectomy' 'Hysterosalpingectomy' 'Hysterosalpingo-oophorectomy' 'Radical hysterectomy')));
RUN;

PROC SORT DATA=adsl_ext;                BY &subj_var.; RUN;
PROC SORT DATA=adae_ext;                BY &subj_var.; RUN;
PROC SORT DATA=hysterectomy NODUPKEY;   BY &subj_var.; RUN;

** N = number of subjects with uterus are subjects without hysterectomy;

data adae_ext;
    merge adae_ext(in=a) hysterectomy(in=b);
    by &subj_var.;
    if a and not b;
RUN;

data adsl_ext;
    merge adsl_ext(in=a) hysterectomy(in=b);
    by &subj_var.;
    if a and not b;
RUN;

%MACRO call_overview(aesi_code=, aesi_label=, outdat=, sort=);

    %LOCAL any_event_cond te_cond rel_cond disc_cond ser_cond;

    %LET any_event_cond = not missing(&aesi_code.);
    %LET te_cond        = trtemfl = 'Y';
    %LET rel_cond       = aerel = 'Y';
    %LET disc_cond      = aeacn = 'DRUG WITHDRAWN';
    %LET ser_cond       = aeser = 'Y';

    %overview_tab(
        data     = adae_ext
      , data_n   = adsl_ext
      , misstext = Missing
      , outdat   = out_table
      , freeline =
      , groups   = "&any_event_cond."                                               * "&any_event_cond.                                                 # Any event"
                   "&any_event_cond. and &te_cond. and &rel_cond."                  * "&any_event_cond. and &te_cond. and &rel_cond.                    #     Study drug-related"
                   "&any_event_cond. and &te_cond. and &disc_cond."                 * "&any_event_cond. and &te_cond. and &disc_cond.                   #     Leading to discontinuation"
                   "&any_event_cond. and &te_cond. and &ser_cond."                  * "&any_event_cond. and &te_cond. and &ser_cond.                    #     Serious"
                   "&any_event_cond. and &te_cond. and &ser_cond. and &rel_cond."   * "&any_event_cond. and &te_cond. and &ser_cond. and &rel_cond.     #         Study drug-related"
                   "&any_event_cond. and &te_cond. and &ser_cond. and &disc_cond."  * "&any_event_cond. and &te_cond. and &ser_cond. and &disc_cond.    #         Leading to discontinuation"
    )

    %m_overview_100_patyears(
        indat       = adae_ext
      , indat_adsl  = adsl_ext
      , indat_mosto = out_table
      , censordt    = enddt
      , startdt     = startdt
      , enddt       = enddt
      , event_var   = aedecod
      , adt         = astdt
      , outdat      = out_table
    )

    DATA &outdat.;
        SET out_table;
         ATTRIB aesi LABEL = "AESI grouping" LENGTH=$200;
         aesi = "&aesi_label.";
         _sort_ = &sort.;
    RUN;
%MEND;

%call_overview(
    aesi_code  = CQ04CD
  , aesi_label = Post-menopausal uterine bleeding (women without hysterectomy are considered)
  , outdat     = aesi_uterine
  , sort       = 1
)

DATA stack_aesi;
    SET aesi_:;
RUN;

DATA stack_aesiinp;
    SET out_tableinp;
    IF keyword = 'DATA'     THEN value = 'STACK_AESI';
    IF keyword = 'BY'       THEN value = catx(' ', '_sort_', 'aesi', value);
    IF keyword = 'ORDER'    THEN value = catx(' ', '_sort_', value);
    IF keyword = 'FREELINE' THEN value = catx(' ', 'aesi'  , value);
RUN;

%set_titles_footnotes(
    tit1 = "Table: Treatment-emergent adverse events of special interest - post-menopausal uterine bleeding up to week 52: overview of number of subjects and study size and exposure-adjusted incidence rate by integrated analysis treatment group KM, 2024-02-19: Added"
  , ftn1 = "Study size and exposure-adjusted IRs are calculated as following: For each study and treatment group, the exposure-adjusted incidence (= number of participants with event / sum of exposure days) is multiplied by the proportion of the study exposure to the total exposure across studies. Results are then added up across all studies for each treatment group."
  , ftn2 = "Where sum of exposure days = sum of time to first treatment-emergent event for participants if an event occurred + sum of treatment duration with time at risk after treatment end for participants without treatment-emergent event."
  , ftn3 = "The time at risk after treatment end is defined as time after end of treatment up to end of treatment-emergent window or death date, whichever is earlier."
  , ftn4 = "Results are provided per 100 person-years, where one person-year is defined as 365.25 days."
  , ftn5 = "*IRs are study size adjusted incidence rates according to Crowe et al (2016)."
  , ftn6 = "N =number of subjects with uterus who received the respective treatment at any time, n=number of subjects with uterus with at least one such event."
  , ftn7 = "&foot_aesi_tab."
)

%LET _line = %SYSFUNC(GETOPTION(LINESIZE));

OPTIONS LINESIZE=250;

%LET MOSTOCALCPERCWIDTH=NO;
%insertOptionRTF(namevar = aesi, width = 55mm, keep = n, overwrite = n)
%insertOptionRTF(namevar = _name_, width = 50mm, keep = n, overwrite = n)
%insertOptionRTF(namevar = _col_01, width = 50mm, keep = n, overwrite = n)
%insertOptionRTF(namevar = _col_02, width = 50mm, keep = n, overwrite = n)


%mosto_param_from_dat(data = stack_aesiinp, var = config)
%datalist(&config)

OPTIONS LINESIZE=&_line.;

%endprog;
