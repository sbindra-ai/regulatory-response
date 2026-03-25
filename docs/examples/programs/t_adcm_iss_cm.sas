/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adcm_iss_cm);
/*
 * Purpose          : Concomitant medication: number of subjects by substance by descending frequency in EZN 120 mg (week 1-52) (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gltlk (Rui Zeng) / date: 21FEB2024
 * Reference prog   :
 ******************************************************************************/

%LET mosto_param_class = %scan(&extend_var_disp_12_26_52_nt_a., 1, '@');

%load_ads_dat(adcm_view, adsDomain = adcm, where = cmcat ne "MEDICATION OF INTEREST")
%load_ads_dat(adsl_view, adsDomain = adsl);

/* EZN 120 mg (week 1-12)
 *  Placebo (week 1-12)
 *      Participants who started with the respective treatment. Analyses on events and outcomes during treatment refer only to the first 12 weeks.
 *      For participants from OASIS 1 and OASIS 2 only events and measurements (starting) up to the end of the 12-week double-blind phase are considered.
 *      For participants from OASIS 3 only events and measurements (starting) during the first 12 weeks (84 days) of treatment are considered.
 *
 *  EZN 120 mg (week 1-26)
 *      Participants treated with Elinzanetant 120 mg at any timepoint. That means participants who started with Elinzanetant 120 mg as well as participants who switched from Placebo to Elinzanetant 120 mg are considered.
 *      Only events and outcomes during the Elinzanetant 120 mg treatment phase are considered, except those starting after day 182 in OASIS 3.

 *  Placebo (week 1-26)
 *      Participants treated with Placebo at any timepoint. That means participants who stayed on Placebo as well as participants who switched to Elinzanetant 120 mg are considered.
 *      For switchers, events and measurements (starting) after the placebo treatment phase are excluded. Also events and measurements (starting) after day 182 in OASIS 3 are excluded.

 *  All EZN 120 mg (week 1-52)
 *      Participants treated with elinzanetant 120 mg  at any timepoint.
 *      That means participants who start with elinzanetant 120 mg as well as participants who switch from placebo to elinzanetant 120 mg are considered.
 *      Only events and outcomes during the EZN  treated phase are considered.
 *  All Placebo (week 1-52)
 *      Participants treated with placebo at any timepoint. That means participants who stay on placebo as well as participants who switch to elinzanetant will be considered.
 *      For switchers, events and measurements (starting) after the placebo-treated phase will be excluded.
 */
%extend_data(
    indat       = adcm_view
  , outdat      = adcm_ext
  , var         = &extend_var_disp_12_26_52_nt_a.
  , extend_rule = trt01an in (53)   and ontr01fl = 'Y'                          /*EZN Phase 1*/                 # &trt_ezn_12.

                @ trt01an in (9901) and ontr01fl = 'Y'                          /*PLA Phase 1*/                 # &trt_pla_12.

                @  (trt01an in (53) and ontr01fl = 'Y')                         /*EZN Phase 1*/
                OR (trt01an in (53) and missing(trt02an) and ontr03fl = 'Y')    /*EZN Phase 2 for non-switcher*/
                OR (trt02an in (53) and ontr03fl = 'Y')                         /*EZN Phase 2 for switcher*/
                                                                                                                # &trt_ezn_26.
                @  (trt01an in (9901) and ontr01fl = 'Y')                       /*PLA Phase 1*/
                OR (trt01an in (9901) and missing(trt02an) and ontr03fl = 'Y')  /*PLA Phase 2 for non-switcher*/
                                                                                                                # &trt_pla_26.

                @  (trt01an in (53) and ontr01fl = 'Y')                         /*EZN Phase 1*/
                OR (trt01an in (53) and missing(trt02an) and ontr02fl = 'Y')    /*EZN Phase 2 for non-switcher*/
                OR (trt02an in (53) and ontr02fl = 'Y')                         /*EZN Phase 2 for switcher*/
                                                                                                                # &trt_ezn_52.
                @  (trt01an in (9901) and ontr01fl = 'Y')                       /*PLA Phase 1*/
                OR (trt01an in (9901) and missing(trt02an) and ontr02fl = 'Y')  /*PLA Phase 2 for non-switcher*/
                                                                                                                # &trt_pla_52.
);

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_12_26_52_nt_a.
  , extend_rule = &extend_rule_disp_12_26_52_nt_a.
);

*Drugs are presented based on their substances. Assignment is done via CAS number.;
*create one observation per substance;
DATA adcm_ext2;
    SET adcm_ext;
    ARRAY c1 s_name:;
    ATTRIB subname LABEL='Substance' FORMAT = $200.;
    DO i = 1 TO dim(c1);
        IF NOT missing(c1{i}) THEN DO;
            subname = c1{i};
            OUTPUT;
        END;
    END;
RUN;

%set_titles_footnotes(
    tit1 = "Table: Concomitant medication: number of subjects by substance by descending frequency in EZN 120 mg (week 1-52) &saf_label."
  , ftn1 = "Medications taken within the treatment period are included in this table."
  , ftn2 = "Medications are presented based on their substances. Assignment is done via CAS number."
);

%incidence_print(
    data        = adcm_ext2
  , data_n      = adsl_ext(WHERE=(&saf_cond.))
  , var         = subname
  , triggercond = cmdecod ne ' '
  , sortorder   = FREQC
  , frqvar      = 5     /* sort by descending frequency in All EZN 120 mg (week 1-52) */
  , evlabel     = Substance#WHO-DD Version &v_whodd.
  , anytxt      = Number (%) of subjects who took at least one concomitant medication
)


%endprog;