/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = tf_adae_iss_cuminc_aesi1_week12_52);
/*
 * Purpose          : Cumulative incidence for time to any treatment-emergent with AESI any condition potentially triggering close liver observation by integrated analysis treatment group (safety analysis set)
 *                    Cumulative incidence curve of time to any treatment-emergent with AESI any condition potentially triggering close liver observation up to week 12 by integrated analysis treatment group (safety analysis set)
 *                    Cumulative incidence curve of time to any treatment-emergent with AESI any condition potentially triggering close liver observation up to week 52 by integrated analysis treatment group (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : erjli (Yosia Hadisusanto) / date: 18MAR2024
 * Reference prog   :
 ******************************************************************************/

%LET mosto_param_class = %scan(&extend_var_disp_12_52_nt_a., 1, '@');

%load_ads_dat(adsl_view, adsDomain = adsl,   where = &saf_cond.);
%load_ads_dat(adae_view, adsDomain = adae, adslwhere=&saf_cond., where = trtemfl = 'Y');

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_12_52_nt_a.
  , extend_rule = &extend_rule_disp_12_52_nt_a.
);

%LET ezn_pure_cond      = (trt01an in (53));
%LET ezn_switcher_cond  = (trt02an in (53) and aphase = 'Week 13-52');
%LET pla_pure_cond      = (trt01an in (9901) and missing(trt02an));
%LET pla_switcher_cond  = (trt02an in (53) and aphase = 'Week 1-12');

%extend_data(
    indat       = adae_view
  , outdat      = adae_ext
  , var         = &extend_var_disp_12_nt_a.
  , extend_rule = (trt01an in (53)   and aphase = 'Week 1-12') # &trt_ezn_12.
                @ (trt01an in (9901) and aphase = 'Week 1-12') # &trt_pla_12.
                @ &ezn_pure_cond. OR &ezn_switcher_cond.       # &trt_ezn_52.
                @ &pla_pure_cond. OR &pla_switcher_cond.       # &trt_pla_52.
);

%m_add_time_window(indat = adsl_ext, outdat = adsl_ext);

%create_adtte_obs(
    indat        = adae_ext
  , subjdat      = adsl_ext
  , outdat       = adtte_aesi
  , startdt      = startdt
  , enddt        = enddt
  , censor_date  = cnsrdt
  , censor_desc  = "Censor date"
  , event_var    = aedecod
  , event_select = not missing(CQ01CD)
  , adt          = astdt
  , avisitn      = 1
  , paramcd      = AESI1
  , srcdom       = 'ADAE'
)

%mergeDat(baseDat = adtte_aesi, keyDat = adsl_ext, by = &subj_var.)

DATA adtte_aesi;
    SET adtte_aesi;
    * If event did not occur by day 84, the participant will be censored at week 12.;
    * the decision is to truncate it at day 84;
    IF &mosto_param_class. IN (&trt_ezn_12., &trt_pla_12.) AND aval > 84 THEN DO;
        aval = 84;
        cnsr = 1;
    END;

    * If event did not occur by day 364, the participant will be censored at week 52.;
    * the decision is to truncate it at day 364;
    IF &mosto_param_class. IN (&trt_ezn_52., &trt_pla_52.) AND aval > 364 THEN DO;
        aval = 364;
        cnsr = 1;
    END;
RUN;

%set_titles_footnotes(
    tit1 = "Table: Cumulative incidence for time to any potential treatment-emergent AESI - liver event by integrated analysis treatment group &saf_label."
  , ftn1 = "&foot_rel_days."
  , ftn2 = "For treatment switchers, the days relative to the start of EZN 120 mg are presented in EZN 120 mg (week 1-26/1-52)."
  , ftn3 = "&foot_cens_sap."
  , ftn4 = "Any condition triggering close liver observation according to protocol Section 10.5. results in true AESIs of liver events. Cases in this table are identified by defined Standardised MedDRA Queries and are beyond the protocol definition."
  , ftn5 = "n = cumulative number of subjects with events up to the day, inclusive. N = number of subjects at risk at start of time point."
  , ftn6 = "Cum. inc = Cumulative Incidence. Cum. inc (%) = Kaplan-Meier estimates of the cumulative probability for an event, calculated as 100*(1 minus the Kaplan-Meier estimates of the survival function)."
  , ftn7 = "CI = Confidence Interval. Kaplan-Meier confidence limits are calculated using the complementary log-log transformation for estimating the standard error."
  , ftn8 = "&foot_aesi_tab."
)

%m_cum_inc(
    indat            = adtte_aesi(WHERE = (&mosto_param_class. IN (&trt_ezn_12. &trt_pla_12. &trt_ezn_52.)))
  , pop_cond         = &saf_cond.
  , timelist         = &timelist_week52_table.
  , timelist_display = 0 1 28 56 84 - &trt_ezn_12.
                     # 0 1 28 56 84 - &trt_pla_12.
)

%set_titles_footnotes(
    tit1 = "Figure: Cumulative incidence curve of time to any potential treatment-emergent AESI - liver event up to week 12 by integrated analysis treatment group &saf_label."
  , ftn1 = "&foot_rel_days."
  , ftn2 = "&foot_risk_plot."
  , ftn3 = "&foot_cens_sap."
  , ftn4 = "Any condition triggering close liver observation according to protocol Section 10.5. results in true AESIs of liver events."
  , ftn5 = "Cases in this table are identified by defined Standardised MedDRA Queries and are beyond the protocol definition."
  , ftn6 = "&foot_aesi_tab. &foot_ia_plot."
)

%m_cum_inc(
    indat    = adtte_aesi(WHERE = (&mosto_param_class. IN (&trt_ezn_12. &trt_pla_12.)))
  , pop_cond = &saf_cond.
  , timelist = &timelist_week12_figure.
  , outtype  = FIGURE
  , fig_file = &prog._12
)

%set_titles_footnotes(
    tit1 = "Figure: Cumulative incidence curve of time to any potential treatment-emergent AESI - liver event up to week 52 by integrated analysis treatment group &saf_label."
  , ftn1 = "&foot_rel_days."
  , ftn2 = "For treatment switchers, the days relative to the start of EZN 120 mg are presented in EZN 120 mg (week 1-26/1-52)."
  , ftn3 = "&foot_risk_plot."
  , ftn4 = "&foot_cens_sap."
  , ftn5 = "Any condition triggering close liver observation according to protocol Section 10.5. results in true AESIs of liver events."
  , ftn6 = "Cases in this table are identified by defined Standardised MedDRA Queries and are beyond the protocol definition."
  , ftn7 = "&foot_aesi_tab. &foot_ia_plot."
)

%m_cum_inc(
    indat         = adtte_aesi(WHERE = (&mosto_param_class. IN (&trt_ezn_52.)))
  , pop_cond      = &saf_cond.
  , timelist      = &timelist_week52_figure.
  , outtype       = FIGURE
  , fig_file      = &prog._52
  , titfoot_scale = 0.98
)


%endprog;