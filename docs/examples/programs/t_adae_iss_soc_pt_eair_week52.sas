/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adae_iss_soc_pt_eair_week52);
/*
 * Purpose          : Treatment-emergent adverse events up to week 52: number of subjects and study size and exposure-adjusted incidence rate by primary system organ class and preferred term by integrated analysis treatment group (safety analysis set)
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
/* Changed by       : erjli (Yosia Hadisusanto) / date: 15MAR2024
 * Reason           : Re-order tables: Worst, related, related max intensity
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

**create numeric variable for ordering of AEOUT;
DATA adae_ext;
    SET adae_ext;
    IF missing(aeout) THEN aeout= 'missing';
    SELECT(aeout);
        WHEN('missing')                           aeoutn = 0;
        WHEN('UNKNOWN')                           aeoutn = 1;
        WHEN('RECOVERED/RESOLVED')                aeoutn = 2;
        WHEN('RECOVERING/RESOLVING')              aeoutn = 3;
        WHEN('RECOVERED/RESOLVED WITH SEQUELAE')  aeoutn = 4;
        WHEN('NOT RECOVERED/NOT RESOLVED')        aeoutn = 5;
        WHEN('FATAL')                             aeoutn = 6;
        OTHERWISE PUT 'ERROR: Term for outcome is unknown. Please check. ' usubjid= aeseq= aeout=;
    END;
RUN;

**create format for ordering of AEOUT;
PROC SQL NOPRINT;
    CREATE TABLE aeoutn_format AS SELECT DISTINCT "AEOUTN" AS fmtname, aeoutn AS start, propcase(aeout, '') AS label FROM adae_ext;
QUIT;

PROC FORMAT CNTLIN=aeoutn_format; RUN;

PROC DATASETS LIB=work MEMTYPE=data;
   MODIFY adae_ext;
   ATTRIB aeoutn FORMAT=aeoutn. LABEL="%scan(%varlabel(adae_view,aeout),1,'/')";
QUIT;

%MACRO call_inc_100_patyears(title=Treatment-emergent adverse events up to week 52, where=1=1);
    %set_titles_footnotes(
        tit1 = "Table: &title.: number of subjects and study size and exposure-adjusted incidence rate by primary system organ class and preferred term by integrated analysis treatment group &saf_label."
      , ftn1 = "Adverse events (AEs) are sorted by alphabetical order of the MedDRA classification."
      , ftn2 = "A subject is counted only once within each primary SOC and preferred term."
      , ftn3 = "N = number of subjects who received the respective treatment at any time, n = number of subjects with at least one such event."
      , ftn4 = "Study size and exposure-adjusted IRs are calculated as following: For each study and treatment group, the exposure-adjusted incidence (= number of participants with event / sum of exposure days) is multiplied by the proportion of the study exposure to the total exposure across studies. Results are then added up across all studies for each treatment group."
      , ftn5 = "Where sum of exposure days = sum of time to first treatment-emergent event for participants if an event occurred + sum of treatment duration with time at risk after treatment end for participants without treatment-emergent event."
      , ftn6 = "The time at risk after treatment end is defined as time after end of treatment up to end of treatment-emergent window or death date, whichever is earlier."
      , ftn7 = "Results are provided per 100 person-years, where one person-year is defined as 365.25 days."
      , ftn8 = "*IRs are study size adjusted incidence rates according to Crowe et al (2016)."
    )

    %m_inc_100_patyears(
        indat       = adae_ext(WHERE=(&where.))
      , indat_adsl  = adsl_ext
      , censordt    = enddt
      , startdt     = startdt
      , var         = aebodsys aedecod
      , triggercond = not missing(aedecod)
      , evlabel     = &evlabel.
      , anytxt      = &anytxt.
    )

%MEND;

%call_inc_100_patyears()

%set_titles_footnotes(
    tit1 = "Table: Treatment-emergent adverse events up to week 52 by maximum intensity: number of subjects by primary system organ class and preferred term by integrated analysis treatment group &saf_label."
  , ftn1 = "Only the most severe intensity is counted for multiple occurrences of the same adverse event in one individual."
  , ftn2 = "'Missing' is considered to be the lowest category of intensity."
  , ftn3 = "Adverse events are sorted by alphabetical order of the MedDRA classification."
  , ftn4 = "A subject is counted only once within each primary SOC and preferred term."
)

%incidence_print(
    data        = adae_ext
  , data_n      = adsl_ext
  , var         = aebodsys aedecod
  , categor     = asevn
  , triggercond = not missing(aeterm)
  , misstext    = Missing
  , sortorder   = alpha
  , evlabel     = &evlabel.
  , anytxt      = &anytxt.
)

%set_titles_footnotes(
    tit1 = "Table: Treatment-emergent adverse events up to week 52 by worst outcome: number of subjects by primary system organ class and preferred term by integrated analysis treatment group &saf_label."
  , ftn1 = "Only the worst outcome is counted for multiple occurrences of the same adverse event in one individual."
  , ftn2 = "Adverse events are sorted by alphabetical order of the MedDRA classification."
  , ftn3 = "A subject is counted only once within each primary SOC and preferred term."
)

%incidence_print(
    data        = adae_ext
  , data_n      = adsl_ext
  , var         = aebodsys aedecod
  , categor     = aeoutn
  , triggercond = not missing(aeterm)
  , misstext    = Missing
  , sortorder   = alpha
  , evlabel     = &evlabel.
  , anytxt      = &anytxt.
  , maxcattxt   = Worst
)

%call_inc_100_patyears(
    title = Treatment-emergent study drug-related adverse events up to week 52
  , where = aerel = 'Y'
)

%set_titles_footnotes(
    tit1 = "Table: Treatment-emergent study drug-related adverse events up to week 52 by maximum intensity: number of subjects by primary system organ class and preferred term by integrated analysis treatment group &saf_label."
  , ftn1 = "Only the most severe intensity is counted for multiple occurrences of the same adverse event in one individual."
  , ftn2 = "'Missing' is considered to be the lowest category of intensity."
  , ftn3 = "Adverse events are sorted by alphabetical order of the MedDRA classification."
  , ftn4 = "A subject is counted only once within each primary SOC and preferred term."
)

%incidence_print(
    data        = adae_ext(WHERE=(aerel = 'Y'))
  , data_n      = adsl_ext
  , var         = aebodsys aedecod
  , categor     = asevn
  , triggercond = not missing(aeterm)
  , misstext    = Missing
  , sortorder   = alpha
  , evlabel     = &evlabel.
  , anytxt      = &anytxt.
)

%set_titles_footnotes(
    tit1 = "Table: Treatment-emergent adverse events up to week 52: number of subjects with reported events under the SMQ accidents and injuries and study size and exposure-adjusted incidence rate by preferred term and integrated analysis treatment group &saf_label."
    , ftn1 = "Adverse events (AEs) are sorted by alphabetical order of the MedDRA classification."
    , ftn2 = "Standardised MedDRA Queries (SMQ) terms: accidents and injuries."
    , ftn3 = "N = number of subjects who received the respective treatment at any time, n = number of subjects with at least one such event. Percentages are calculated relative to the respective treatment group. Subjects may be counted in more than one row."
    , ftn4 = "Study size and exposure-adjusted IRs are calculated as following: For each study and treatment group, the exposure-adjusted incidence (= number of participants with event / sum of exposure days) is multiplied by the proportion of the study exposure to the total exposure across studies. Results are then added up across all studies for each treatment group."
    , ftn5 = "Where sum of exposure days = sum of time to first treatment-emergent event for participants if an event occurred + sum of treatment duration with time at risk after treatment end for participants without treatment-emergent event."
    , ftn6 = "The time at risk after treatment end is defined as time after end of treatment up to end of treatment-emergent window or death date, whichever is earlier."
    , ftn7 = "Results are provided per 100 person-years, where one person-year is defined as 365.25 days."
    , ftn8 = "*IRs are study size adjusted incidence rates according to Crowe et al (2016)."
)

%m_inc_100_patyears(
    indat       = adae_ext(WHERE=(cq06cd = 6)) %** Z_CQNAM.6 [Accidents and injuries];
  , indat_adsl  = adsl_ext
  , censordt    = enddt
  , startdt     = startdt
  , var         = aedecod
  , triggercond = not missing(aedecod)
  , evlabel     = Preferred Term#   MedDRA Version &v_meddra.
  , anytxt      = &anytxt.
)

%call_inc_100_patyears(
    title = Treatment-emergent serious adverse events up to week 52
  , where = aeser = 'Y'
)

%call_inc_100_patyears(
    title = Treatment-emergent study drug-related serious adverse events up to week 52
  , where = aeser = 'Y' and aerel = 'Y'
)

%call_inc_100_patyears(
    title = Treatment-emergent adverse events up to week 52 with fatal outcome
  , where = aesdth = 'Y'
)

%call_inc_100_patyears(
    title = Treatment-emergent adverse events resulting in discontinuation of study drug up to week 52
  , where = aeacn = 'DRUG WITHDRAWN'
)

%call_inc_100_patyears(
    title = Treatment-emergent study drug-related adverse events resulting in discontinuation of study drug up to week 52
  , where = aerel = 'Y' and aeacn = 'DRUG WITHDRAWN'
)

%call_inc_100_patyears(
    title = Treatment-emergent serious adverse events resulting in discontinuation of study drug up to week 52
  , where = aeser = 'Y' and aeacn = 'DRUG WITHDRAWN'
)

%endprog;