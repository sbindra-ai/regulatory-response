/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adsl_ise_site_reg);
/*
 * Purpose          : Create table: Number of sites by pooled region and country/ region (all randomized subjects)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gltlk (Rui Zeng) / date: 28NOV2023
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : eqczz (Petri Pulkkinen) / date: 01DEC2023
 * Reason           : Changing country_c to proper case
 ******************************************************************************/
/* Changed by       : gltlk (Rui Zeng) / date: 12JAN2024
 * Reason           : add STUDYID to parameter subject
 ******************************************************************************/

%LET mosto_param_class = _temp_site;

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
    _temp_site='Study Sites';
RUN;

%set_titles_footnotes(
    tit1 = "Table: Number of sites by pooled region and country/region &rand_label."
);

%freq_tab(
    data         = adsl_ext
  , data_n       = adsl_ext
  , var          = country_c
  , subject      = studyid siteid /*Note: count number of study sites, not subjects!*/
  , by           = region1n
  , totalby      = region1n
  , totaltxt     = %str(All)
  , class        = _temp_site
  , order        = country
  , hlabel       = YES
  , subjectlabel = Total
  , complete     = MIN
  , freeline     = region1n
)

%endprog();
