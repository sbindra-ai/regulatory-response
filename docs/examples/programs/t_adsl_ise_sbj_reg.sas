/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adsl_ise_sbj_reg);
/*
 * Purpose          : Create table: Number of subjects by pooled region and country/region (all randomized subjects)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gltlk (Rui Zeng) / date: 29NOV2023
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : eqczz (Petri Pulkkinen) / date: 01DEC2023
 * Reason           : Changing country_c to proper case
 ******************************************************************************/

%LET mosto_param_class = &mosto_param_class_eff.;

%load_ads_dat(
    adsl_view
  , adsDomain = adsl
  , where     = &rand_cond.
);
%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_eff.
  , extend_rule = &extend_rule_disp_eff.
);

data adsl_ext;
    set adsl_ext;
    format country $country.;
    ATTRIB country_c LENGTH=$200 label = "Country/ Region";
    country_c = propcase(put(country, $country.));
RUN;

%set_titles_footnotes(
    tit1 = "Table: Number of subjects by pooled region and country/region &rand_label."
  , ftn1 = "&foot_placebo_ezn."
);

%freq_tab(
    data         = adsl_ext
  , data_n       = adsl_ext
  , var          = country_c
  , by           = region1n
  , totalby      = region1n
  , totaltxt     = %str(All)
  , order        = country
  , hlabel       = YES
  , subjectlabel = Total
  , complete     = MIN
  , total        = YES
  , freeline     = region1n
)

%endprog();
