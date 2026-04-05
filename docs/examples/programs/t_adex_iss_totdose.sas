/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adex_iss_totdose);
/*
 * Purpose          : Create table: Total dose of elinzanetant by integrated analysis treatment group (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gltlk (Rui Zeng) / date: 27FEB2024
 * Reference prog   :
 ******************************************************************************/

** >>> START: Total dose by integrated analysis treatment group (safety analysis set);
%LET mosto_param_class = %scan(&extend_var_disp_ezn_a., 1, '@');

*get data and select only Safety patients;
%load_ads_dat(adsl_view, adsDomain = adsl, where = &saf_cond.)
%load_ads_dat(
    adex_view
  , adsDomain = adex
  , where     = paramcd = 'TOTDOSE' and aval ne .
  , adslWhere = &saf_cond.
)

*Extend treatment group as needed;
%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_ezn_a.
  , extend_rule = &extend_rule_disp_ezn_a.
);

%extend_data(
    indat       = adex_view
  , outdat      = adex_ext
  , var         = &extend_var_disp_ezn_a.
  , extend_rule = &extend_rule_disp_exposure_ezn.
);

DATA adex_ext2;
    SET adex_ext;

    LABEL aval ="Total dose (g)";
          aval=aval/1000;          *Converting mg to gram;
RUN;

%set_titles_footnotes(
    tit1 = "Table: Total dose of elinzanetant by integrated analysis treatment group &saf_label."
    ,ftn1 = "Data for total dose of Elinzanetant 120 mg is collected via ePRO daily instrument 'Study drug intake documentation'."
    ,ftn2 = "For OASIS 3, Week 1-26 is defined from start of study treatment until day 182 (inclusive)."
    ,ftn3 = "&foot_sd."
);

%desc_freq_tab(
    data         = adex_ext2
  , var          = aval
  , data_n       = adsl_ext
  , stat         = n nmiss mean std min median max
  , round_factor = 0.1
)

** <<< END: Create table - Total dose by integrated analysis treatment group (safety analysis set);

%endprog();