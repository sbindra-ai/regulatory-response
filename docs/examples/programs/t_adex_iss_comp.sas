/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adex_iss_comp);
/*
 * Purpose          : Create table: Treatment compliance by integrated analysis treatment group (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gltlk (Rui Zeng) / date: 28FEB2024
 * Reference prog   :
 ******************************************************************************/

** >>> START: Treatment compliance by integrated analysis treatment group (safety analysis set);
%LET mosto_param_class = %scan(&extend_var_disp_12_26_52_nt_a., 1, '@');

*get data and select only Safety patients;
%load_ads_dat(adsl_view, adsDomain = adsl, where = &saf_cond. )
%load_ads_dat(
    adex_view
  , adsDomain = adex
  , where     = paramcd = 'COMPLPRC' and aval ne .
  , adslWhere = &saf_cond.
)

*Extend treatment group as needed;
%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_12_26_52_nt_a.
  , extend_rule = &extend_rule_disp_12_26_52_nt_a.
);

%extend_data(
    indat       = adex_view
  , outdat      = adex_ext
  , var         = &extend_var_disp_12_26_52_nt_a.
  , extend_rule = &extend_rule_disp_exposure.
);

DATA adex_ext2;
    SET adex_ext;

    LABEL aval     = "a0"x
          avalca1n = "Categories N (%)"
          param    = "a0"x;
    param = 'Treatment compliance (%)';

RUN;

%set_titles_footnotes(
    tit1 = "Table: Treatment compliance by integrated analysis treatment group &saf_label."
    ,ftn1 = "Treatment compliance (%) = 100 * Number of capsules taken / Number of planned capsules per protocol."
    ,ftn2 = "Number of planned capsules = Treatment duration * the planned daily total number of capsules."
    ,ftn3 = "For SWITCH-1 study only daily intake of study drug (Yes/No) was recorded. For compliance calculation 'Yes' means daily number of capsules is 4 and 'No' means 0 capsule."
    ,ftn4 = "Data for number of capsules is collected via ePRO daily instrument 'Study drug intake documentation'."
    ,ftn5 = "Duration of treatment is based on the data collected via the eCRF."
    ,ftn6 = "For OASIS 3, Week 1-26 is defined from start of study treatment until day 182 (inclusive)."
    ,ftn7 = "&foot_sd."
)
;

%desc_freq_tab(
    data          = adex_ext2
  , var           = aval avalca1n
  , data_n        = adsl_ext
  , by            = param
  , data_n_ignore = param
  , levlabel      = yes
  , stat          = n nmiss mean std min median max
  , round_factor  = 0.1
)

** <<< END: Treatment compliance by integrated analysis treatment group (safety analysis set);

%endprog();