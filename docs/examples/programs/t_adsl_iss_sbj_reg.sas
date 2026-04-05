/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adsl_iss_sbj_reg);
/*
 * Purpose          : Number of subjects by country/region (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        :  erjli (Yosia Hadisusanto) / date: 23OCT2023
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : erjli (Yosia Hadisusanto) / date: 29FEB2024
 * Reason           : Add Label Country/Region
 ******************************************************************************/

%LET mosto_param_class = %SCAN(&extend_var_disp_12_a., 1, @);

%load_ads_dat(adsl_view, adsDomain = adsl);
%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_12_a.
  , extend_rule = &extend_rule_disp_12_a.
);

data adsl_ext;
    set adsl_ext;
    format country $country.;
    ATTRIB country_c LENGTH=$200;
    country_c = put(country, $country.);
RUN;

%set_titles_footnotes(
    tit1 = "Table: Number of subjects by pooled region and country/region &saf_label."
  , ftn1 = "N = number of subjects. Percentages are calculated relative to the respective treatment group."
  , ftn2 = "EZN 120 mg (week 1-12) and Placebo (week 1-12) refer to participants who start with the respective treatment."
  , ftn3 = "Total (week 1-12) refers to all participants who started any study drug."
);

%freq_tab(
    data              = adsl_ext
  , data_n            = adsl_ext (WHERE = (&saf_cond.))
  , var               = country_c
  , by                = region1n
  , totalby           = region1n
  , totaltxt          = %str(All)
  , order             = country
  , hlabel            = YES
  , subjectlabel      = Total
  , outdat            = outdat
  , harmonized_outdat = no
  , complete          = MIN
)

** Add N (100%);
DATA outdat;
    SET outdat;
    ATTRIB _cptog1 LABEL="%varlabel(outdat, _cptog1) # N (100%)";
    ATTRIB _cptog2 LABEL="%varlabel(outdat, _cptog2) # N (100%)";
    ATTRIB _cptog3 LABEL="%varlabel(outdat, _cptog3) # N (100%)";
    ATTRIB _varl_  LABEL="Country/Region";
RUN;

%mosto_param_from_dat(data = outdatinp, var = config)
%datalist(&config)


%endprog();

