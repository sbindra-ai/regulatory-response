/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adae_iss_soc_pt_week12_subgrp);
/*
 * Purpose          : Treatment-emergent adverse events up to week 12: number of subjects by primary system organ class, preferred term and integrated analysis treatment group by <<subgroup>> (safety analysis set)
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

%let mosto_param_class = %scan(&extend_var_disp_12_nt_a., 1, '@');

%load_ads_dat(adsl_view, adsDomain = adsl, where     = &saf_cond.)
%load_ads_dat(adae_view, adsDomain = adae, adslWhere = &saf_cond., where = trtemfl = 'Y')

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_12_nt_a.
  , extend_rule = &extend_rule_disp_12_nt_a.
)

%extend_data(
    indat       = adae_view
  , outdat      = adae_ext
  , var         = &extend_var_disp_12_nt_a.
  , extend_rule = (trt01an in (53)   and aphase = 'Week 1-12') # &trt_ezn_12.
                @ (trt01an in (9901) and aphase = 'Week 1-12') # &trt_pla_12.
)

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

%MACRO call_inc_print(where=1=1, title=Treatment-emergent adverse events up to week 12, by = &each_item., by_title = by %varlabel(adsl_ext, &each_item.));

    %set_titles_footnotes(
        tit1 = "Table: &title.: number of subjects by primary system organ class, preferred term and integrated analysis treatment group &by_title. &saf_label."
      , ftn1 = "Adverse events (AEs) are sorted by alphabetical order of the MedDRA classification."
      , ftn2 = "A subject is counted only once within each primary SOC and preferred term."
      , ftn3 = "N = number of subjects. Percentages are calculated relative to the respective treatment group. Subjects may be counted in more than one row."
      , ftn4 = %sysfunc(putc(&by., $subgroupfnt.))
    )

    %incidence_print(
        data        = adae_ext(WHERE=(&where.))
      , data_n      = adsl_ext
      , page        = &by.
      , var         = aebodsys aedecod
      , triggercond = not missing(aedecod)
      , sortorder   = alpha
      , together    =
      , evlabel     = &evlabel.
      , anytxt      = &anytxt.
    )

%MEND;

%m_loop(
    macro_name = call_inc_print
  , list       = &subgroup_vars.
  , list_item  = each_item
);

%m_loop(
    macro_name = call_inc_print(where = aeser = 'Y', title = Treatment-emergent serious adverse events up to week 12)
  , list       = &subgroup_vars.
  , list_item  = each_item
);

%m_loop(
    macro_name = call_inc_print(where = aeacn = 'DRUG WITHDRAWN', title = Treatment-emergent adverse events resulting in discontinuation of study drug up to week 12)
  , list       = &subgroup_vars.
  , list_item  = each_item
);

%m_loop(
    macro_name = call_inc_print(where = aeser = 'Y' and aeacn = 'DRUG WITHDRAWN', title = Treatment-emergent serious adverse events resulting in discontinuation of study drug up to week 12)
  , list       = &subgroup_vars.
  , list_item  = each_item
);


%endprog;