/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_3_2_1_adae_pretrtsocpt, log2file = Y);
/*
 * Purpose          : Pre-treatment adverse events: number of subjects by primary system organ class and preferred term  (SAF)
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : enpjp (Prashant Patel) / date: 10SEP2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_3_2_1_adae_pretrtsocpt.sas (enpjp (Prashant Patel) / date: 09SEP2023)
 ******************************************************************************/


*get data and select only Safety patients;
%load_ads_dat(adae_view, adsDomain = adae, where = prefl eq "Y", adslWhere = &saf_cond.)
%load_ads_dat(adsl_view, adsDomain = adsl, where = &saf_cond, adslVars  =);

%extend_data(indat = adsl_view, outdat = adsl)
%extend_data(indat = adae_view, outdat = adae)

%mtitle;
%incidence_print(
    data        = adae_view
  , data_n      = adsl_view
  , var         = aebodsys aedecod
  , class       = trt01an
  , triggercond = aeterm ne ' '
  , total       = YES
  , sortorder   = FREQA
  , evlabel     = Primary System Organ Class#   Preferred Term#   MedDRA Version &v_meddra
  , anytxt      = Number (%) of subjects with at least one such adverse event
  , maxlen      = 40
  , hsplit      = '#@'
)

/* Use %endprog at the end of each study program */
%endprog;