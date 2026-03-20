/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adae_iss_soc_pt_week52_subgrp);
/*
 * Purpose          : Treatment-emergent adverse events up to week 52: number of subjects and study size and exposure-adjusted incidence rate
 *                    by primary system organ class, preferred term and integrated analysis treatment group by <<subgroup>> (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : erjli (Yosia Hadisusanto) / date: 19DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/ia/stat/main001/dev/analysis/pgms/t_adae_iss_soc_pt_eair_week52.sas
 ******************************************************************************/

%LET mosto_param_class = %scan(&extend_var_disp_52_nt_a., 1, '@');

%load_ads_dat(adsl_view, adsDomain = adsl, where     = &saf_cond.)
%load_ads_dat(adae_view, adsDomain = adae, adslWhere = &saf_cond., where = trtemfl = 'Y')

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

%m_add_time_window(indat = adsl_ext, outdat = adsl_ext);

DATA adsl_ext;
    SET adsl_ext;

    ATTRIB racen     FORMAT=_race.     LABEL = "%varlabel(adsl_ext, race)";
    ATTRIB ethnicn   FORMAT=_ethnic.   LABEL = "%varlabel(adsl_ext, ethnic)";

    %M_PropIt(Var = race)
    %M_PropIt(Var = ethnic)
    IF race_prop NE ' ' THEN DO;
        racen = input(strip(put(RACE_PROP, $_race.)), 3.) ;
    END;
    ethnicn = input(strip(put(ETHNIC_PROP, $_ethnic.)),3.) ;
RUN;

%mergeDat(
    baseDat = adae_ext
  , keyDat  = adsl_ext(KEEP=&subj_var. racen ethnicn)
  , by      = &subj_var.
)

%MACRO call_inc_100_patyears(title=Treatment-emergent adverse events up to week 52, where=1=1, by = &each_item., by_title = by %varlabel(adsl_ext, &each_item.));
    %set_titles_footnotes(
        tit1 = "Table: &title.: number of subjects and study size and exposure-adjusted incidence rate by primary system organ class, preferred term and integrated analysis treatment group &by_title. &saf_label."
      , ftn1 = "Adverse events (AEs) are sorted by alphabetical order of the MedDRA classification."
      , ftn2 = "A subject is counted only once within each primary SOC and preferred term."
      , ftn3 = "N = number of subjects who received the respective treatment at any time, n = number of subjects with at least one such event."
      , ftn4 = "Study size and exposure-adjusted IRs are calculated as following: For each study and treatment group, the exposure-adjusted incidence (= number of participants with event / sum of exposure days) is multiplied by the proportion of the study exposure to the total exposure across studies. Results are then added up across all studies for each treatment group."
      , ftn5 = "Where sum of exposure days = sum of time to first treatment-emergent event for participants if an event occurred + sum of treatment duration with time at risk after treatment end for participants without treatment-emergent event."
      , ftn6 = "The time at risk after treatment end is defined as time after end of treatment up to end of treatment-emergent window or death date, whichever is earlier."
      , ftn7 = "Results are provided per 100 person-years, where one person-year is defined as 365.25 days. *IRs are study size adjusted incidence rates according to Crowe et al (2016)."
      , ftn8 = %sysfunc(putc(&by., $subgroupfnt.))
    )

    %m_inc_100_patyears(
        indat       = adae_ext(WHERE=(&where.))
      , by          = &by.
      , indat_adsl  = adsl_ext
      , censordt    = enddt
      , startdt     = startdt
      , var         = aebodsys aedecod
      , triggercond = not missing(aedecod)
      , evlabel     = &evlabel.
      , anytxt      = &anytxt.
    )

%MEND;

%m_loop(
    macro_name = call_inc_100_patyears
  , list       = &subgroup_vars.
  , list_item  = each_item
);

%m_loop(
    macro_name = call_inc_100_patyears(title = Treatment-emergent serious adverse events up to week 52, where = aeser = 'Y')
  , list       = &subgroup_vars.
  , list_item  = each_item
);

%m_loop(
    macro_name = call_inc_100_patyears(title = Treatment-emergent adverse events resulting in discontinuation of study drug up to week 52, where = aeacn = 'DRUG WITHDRAWN')
  , list       = &subgroup_vars.
  , list_item  = each_item
);

%m_loop(
    macro_name = call_inc_100_patyears(title = Treatment-emergent serious adverse events resulting in discontinuation of study drug up to week 52, where = aeser = 'Y' and aeacn = 'DRUG WITHDRAWN')
  , list       = &subgroup_vars.
  , list_item  = each_item
);


%endprog;