/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_1_1_adsl_smpsz);
/*
 * Purpose          : Study sample sizes by <<trial unit/pooled region/country/region>> (all enrolled subjects)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : enpjp (Prashant Patel) / date: 10SEP2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_1_1_adsl_smpsz.sas (enpjp (Prashant Patel) / date: 09SEP2023)
 ******************************************************************************/

%load_ads_dat(adsl_view, adsDomain = adsl, where = &ENR_COND.)

%extend_data(indat = adsl_view, outdat = adsl)

%mtitle;

%dispositionpss(
    data        = adsl_view
  , by          = siteid
  , class       = &TREAT_ARM_P
  , groups      = "randfl='Y'"  *'Randomized'
                 "fasfl='Y'"  *'Valid for Full Analysis Set'
                 "saffl='Y'"   *'Valid for Safety Analysis Set'
                 "slasfl='Y'"   *'Valid for Sleep Analysis Set'
  , groupstxt   = Number of Subjects
  , groupspct   = YES
  , dates       = 'MIN(rficdt)'       *'Date of First Consent'
                  'MAX(lvdt)'         *'Date of Last Visit'
  , enrolledtxt = Enrolled
  , subject     = usubjid
  , totalby     = siteid
  , totalpage   = siteid
);

%endprog()

