/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = tf_adae_iss_cuminc_disc_week12);
/*
 * Purpose          : Cumulative incidences for time to any treatment-emergent adverse event resulting in discontinuation of study drug up to 12 weeks by integrated analysis treatment group (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : erjli (Yosia Hadisusanto) / date: 14FEB2024
 * Reference prog   :
 ******************************************************************************/

%let mosto_param_class = %scan(&extend_var_disp_12_nt_a., 1, '@');

%load_ads_dat(adsl_view, adsDomain = adsl, where = &saf_cond.);
%load_ads_dat(adae_view, adsDomain = adae, adslwhere = &saf_cond., where = trtemfl = 'Y');

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_12_nt_a.
  , extend_rule = &extend_rule_disp_12_nt_a.
);

%extend_data(
    indat       = adae_view
  , outdat      = adae_ext
  , var         = &extend_var_disp_12_nt_a.
  , extend_rule = (trt01an in (53)   and aphase = 'Week 1-12') # &trt_ezn_12.
                @ (trt01an in (9901) and aphase = 'Week 1-12') # &trt_pla_12.
);

%m_add_time_window(indat = adsl_ext, outdat = adsl_ext);

%create_adtte_obs(
    indat        = adae_ext
  , subjdat      = adsl_ext
  , outdat       = adtte_teae
  , startdt      = startdt
  , enddt        = enddt
  , censor_date  = cnsrdt
  , censor_desc  = "Treatment end date"
  , event_var    = aedecod
  , event_select = aeacn = 'DRUG WITHDRAWN'
  , adt          = astdt
  , avisitn      = 1
  , paramcd      = TEAE
  , srcdom       = 'ADAE'
)

%mergeDat(baseDat = adtte_teae, keyDat = adsl_ext, by = &subj_var.)

DATA adtte_teae;
    SET adtte_teae;
    * If event did not occur by day 84, the participant will be censored at week 12.;
    * the decision is to truncate it at day 84;
    IF &mosto_param_class. IN (&trt_ezn_12., &trt_pla_12.) AND aval > 84 THEN DO;
        aval = 84;
        cnsr = 1;
    END;
RUN;

%create_adtte_obs(
    indat        = adae_ext
  , subjdat      = adsl_ext
  , outdat       = adtte_teaeser
  , startdt      = startdt
  , enddt        = enddt
  , censor_date  = cnsrdt
  , censor_desc  = "Treatment end date"
  , event_var    = aedecod
  , event_select = aeacn = 'DRUG WITHDRAWN' and aeser = 'Y'
  , adt          = astdt
  , avisitn      = 1
  , paramcd      = TEAESER
  , srcdom       = 'ADAE'
)

%mergeDat(baseDat = adtte_teaeser, keyDat = adsl_ext, by = &subj_var.)

DATA adtte_teaeser;
    SET adtte_teaeser;
    * If event did not occur by day 84, the participant will be censored at week 12.;
    * the decision is to truncate it at day 84;
    IF &mosto_param_class. IN (&trt_ezn_12., &trt_pla_12.) AND aval > 84 THEN DO;
        aval = 84;
        cnsr = 1;
    END;
RUN;

%set_titles_footnotes(
    tit1 = "Table: Cumulative incidence for time to any treatment-emergent adverse event resulting in discontinuation of study drug up to 12 weeks by integrated analysis treatment group &saf_label."
  , ftn1 = "&foot_rel_days."
  , ftn2 = "n = cumulative number of subjects with events up to the day, inclusive. N = number of subjects at risk at start of time point."
  , ftn3 = "Cum. inc = Cumulative Incidence. Cum. inc (%) = Kaplan-Meier estimates of the cumulative probability for an event, calculated as 100*(1 minus the Kaplan-Meier estimates of the survival function)."
  , ftn4 = "CI = Confidence Interval. Kaplan-Meier confidence limits are calculated using the complementary log-log transformation for estimating the standard error."
  , ftn5 = "&foot_cens_sap."
)

%m_cum_inc(
    indat    = adtte_teae
  , pop_cond = &saf_cond.
  , timelist = &timelist_week12_table.
)

%set_titles_footnotes(
    tit1 = "Figure: Cumulative incidence curve of treatment-emergent adverse event resulting in discontinuation of study drug up to week 12 by integrated analysis treatment group &saf_label."
  , ftn1 = "&foot_rel_days."
  , ftn2 = "&foot_cens_sap."
  , ftn3 = "&foot_risk_plot."
  , ftn4 = "IA =Integrated Analysis."
)

%m_cum_inc(
    indat    = adtte_teae
  , pop_cond = &saf_cond.
  , timelist = &timelist_week12_figure.
  , outtype  = FIGURE
  , fig_file = &prog.
)

%set_titles_footnotes(
    tit1 = "Table: Cumulative incidence for time to any treatment-emergent serious adverse event resulting in discontinuation of study drug up to 12 weeks by integrated analysis treatment group &saf_label."
  , ftn1 = "&foot_rel_days."
  , ftn2 = "n = cumulative number of subjects with events up to the day, inclusive. N = number of subjects at risk at start of time point."
  , ftn3 = "Cum. inc = Cumulative Incidence. Cum. inc (%) = Kaplan-Meier estimates of the cumulative probability for an event, calculated as 100*(1 minus the Kaplan-Meier estimates of the survival function)."
  , ftn4 = "CI = Confidence Interval. Kaplan-Meier confidence limits are calculated using the complementary log-log transformation for estimating the standard error."
  , ftn5 = "&foot_cens_sap."
)

%m_cum_inc(
    indat    = adtte_teaeser
  , pop_cond = &saf_cond.
  , timelist = &timelist_week12_table.
)

%set_titles_footnotes(
    tit1 = "Figure: Cumulative incidence curve of serious treatment-emergent adverse event resulting in discontinuation of study drug up to week 12 by integrated analysis treatment group &saf_label."
  , ftn1 = "&foot_rel_days."
  , ftn2 = "&foot_cens_sap."
  , ftn3 = "&foot_risk_plot."
  , ftn4 = "IA =Integrated Analysis."
)

data adtte_teaeser;
    set adtte_teaeser;
    attrib &mosto_param_class. FORMAT = _trtgrp.;
RUN;

%m_cum_inc(
    indat    = adtte_teaeser
  , pop_cond = &saf_cond.
  , timelist = &timelist_week12_figure.
  , outtype  = FIGURE
  , fig_file = &prog._aeser
)

%endprog;