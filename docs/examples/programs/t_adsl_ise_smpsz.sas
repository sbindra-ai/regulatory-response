/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adsl_ise_smpsz);
/*
 * Purpose          : Create table: Study sample sizes by study and region (all enrolled subjects)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gltlk (Rui Zeng) / date: 05DEC2023
 * Reference prog   :
 ******************************************************************************/

%LET mosto_param_class = &mosto_param_class_eff.;

%load_ads_dat(
    adsl_view
  , adsDomain = adsl
  , where     = &enr_cond.
);

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_eff.
  , extend_rule = &extend_rule_disp_eff.
);

%set_titles_footnotes(
    tit1 = "Table: Study sample sizes by study and pooled region &enr_label."
  , ftn1 = "&foot_placebo_ezn."
  , ftn2 = "Number of subjects enrolled is the number of subjects who signed informed consent."
  , ftn3 = "&foot_eff_studies."
)

%dispositionpss(
    data        = adsl_ext
  , by          = studyid region1n
  , groups      = "randfl='Y'"        *'Randomized'
                  "fasfl='Y'"         *'Valid for Full Analysis Set'
  , groupstxt   = Number of subjects
  , groupspct   = YES
  , dates       = 'MIN(rficdt)'       *'Date of First Consent'
                  'MAX(lvdt)'         *'Date of Last Visit'
  , enrolledtxt = Enrolled
  , totalby     = studyid region1n
  , maxlen      = 25
)

%endprog;