/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = tf_adae_iss_cuminc_disc_week52);
/*
 * Purpose          : Cumulative incidence for time to any treatment-emergent adverse event resulting in discontinuation of study drug up to 52 weeks by integrated analysis treatment group (safety analysis set)
 *
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
/* Changed by       : erjli (Yosia Hadisusanto) / date: 21DEC2023
 * Reason           : Add relative days footnote in figure
 *                    Remove TEAE and TESAE footnotes
 ******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 14FEB2024
 * Reason           : # Delete &foot_swithcher_disc.
 *                    # Add format _trtgrp_ns_notsplitted. as class_fmt
 *                    # Change extend_var_... and extend_rule_...
 ******************************************************************************/
/* Changed by       : erjli (Yosia Hadisusanto) / date: 14FEB2024
 * Reason           : Update header
 ******************************************************************************/

%LET mosto_param_class = %scan(&extend_var_disp_26_52_a_nt., 1, '@');

%load_ads_dat(adsl_view, adsDomain = adsl, where     = &saf_cond.)
%load_ads_dat(adae_view, adsDomain = adae, adslWhere = &saf_cond., where = trtemfl = 'Y')

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_26_52_a_nt.
  , extend_rule = &extend_rule_disp_26_52_a_nt.
)

%LET ezn_pure_cond      = (trt01an in (53));
%LET ezn_switcher_cond  = (trt02an in (53) and aphase = 'Week 13-52');
%LET pla_pure_cond      = (trt01an in (9901) and missing(trt02an));
%LET pla_switcher_cond  = (trt02an in (53) and aphase = 'Week 1-12');

%extend_data(
    indat       = adae_view
  , outdat      = adae_ext
  , var         = &extend_var_disp_26_52_a_nt.
  , extend_rule = &ezn_pure_cond. OR &ezn_switcher_cond. # &trt_ezn_52.
                @ &pla_pure_cond. OR &pla_switcher_cond. # &trt_pla_52.
)

%m_add_time_window(indat = adsl_ext, outdat = adsl_ext);

%create_adtte_obs(
    indat        = adae_ext
  , subjdat      = adsl_ext
  , outdat       = adtte_teae
  , startdt      = startdt
  , enddt        = enddt
  , censor_date  = cnsrdt
  , censor_desc  = "Treatment end date Week 1-52"
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
    * If event did not occur by day 364, the participant will be censored at week 52.;
    * the decision is to truncate it at day 364;
    IF &mosto_param_class. IN (&trt_ezn_52., &trt_pla_52.) AND aval > 364 THEN DO;
        aval = 364;
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
  , censor_desc  = "Treatment end date Week 1-52"
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
    * If event did not occur by day 364, the participant will be censored at week 52.;
    * the decision is to truncate it at day 364;
    IF &mosto_param_class. IN (&trt_ezn_52., &trt_pla_52.) AND aval > 364 THEN DO;
        aval = 364;
        cnsr = 1;
    END;
RUN;

%set_titles_footnotes(
    tit1 = "Table: Cumulative incidence for time to any treatment-emergent adverse event resulting in discontinuation of study drug up to week 52 by integrated analysis treatment group &saf_label."
  , ftn1 = "&foot_rel_days."
  , ftn2 = "&foot_switcher."
  , ftn3 = "&foot_cens_sap."
  , ftn4 = "n = cumulative number of subjects with events up to the day, inclusive. N = number of subjects at risk at start of time point."
  , ftn5 = "Cum. inc = Cumulative Incidence. Cum. inc (%) = Kaplan-Meier estimates of the cumulative probability for an event, calculated as 100*(1 minus the Kaplan-Meier estimates of the survival function)."
  , ftn6 = "CI = Confidence Interval. Kaplan-Meier confidence limits are calculated using the complementary log-log transformation for estimating the standard error."
)

%m_cum_inc(
    indat     = adtte_teae
  , pop_cond  = &saf_cond.
  , class_fmt = _trtgrp_ns_notsplitted.
  , timelist  = &timelist_week52_table.
)

%set_titles_footnotes(
    tit1 = "Figure: Cumulative incidence curve of treatment-emergent adverse event resulting in discontinuation of study drug up to week 52 by integrated analysis treatment group &saf_label."
  , ftn1 = "&foot_rel_days."
  , ftn2 = "&foot_switcher."
  , ftn3 = "&foot_cens_sap."
  , ftn4 = "&foot_risk_plot."
  , ftn5 = "IA =Integrated Analysis."
)

%m_cum_inc(
    indat         = adtte_teae
  , pop_cond      = &saf_cond.
  , class_fmt     = _trtgrp_ns_notsplitted.
  , timelist      = &timelist_week52_figure.
  , outtype       = FIGURE
  , fig_file      = &prog.
  , titfoot_scale = 0.98
)

%set_titles_footnotes(
    tit1 = "Table: Cumulative incidence for time to any treatment-emergent serious adverse event resulting in discontinuation of study drug up to week 52 by integrated analysis treatment group &saf_label."
  , ftn1 = "&foot_rel_days."
  , ftn2 = "&foot_switcher."
  , ftn3 = "&foot_cens_sap."
  , ftn4 = "n = cumulative number of subjects with events up to the day, inclusive. N = number of subjects at risk at start of time point."
  , ftn5 = "Cum. inc = Cumulative Incidence. Cum. inc (%) = Kaplan-Meier estimates of the cumulative probability for an event, calculated as 100*(1 minus the Kaplan-Meier estimates of the survival function)."
  , ftn6 = "CI = Confidence Interval. Kaplan-Meier confidence limits are calculated using the complementary log-log transformation for estimating the standard error."
)

%m_cum_inc(
    indat     = adtte_teaeser
  , pop_cond  = &saf_cond.
  , class_fmt = _trtgrp_ns_notsplitted.
  , timelist  = &timelist_week52_table.
)

%set_titles_footnotes(
    tit1 = "Figure: Cumulative incidence curve of treatment-emergent serious adverse event resulting in discontinuation of study drug up to week 52 by integrated analysis treatment group &saf_label."
  , ftn1 = "&foot_rel_days."
  , ftn2 = "&foot_switcher."
  , ftn3 = "&foot_cens_sap."
  , ftn4 = "&foot_risk_plot."
  , ftn5 = "IA = Integrated Analysis."
)

%m_cum_inc(
    indat         = adtte_teaeser
  , pop_cond      = &saf_cond.
  , class_fmt     = _trtgrp_ns_notsplitted.
  , timelist      = &timelist_week52_figure.
  , outtype       = FIGURE
  , fig_file      = &prog._aeser
  , titfoot_scale = 0.98
)



%endprog;