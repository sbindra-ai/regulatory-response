/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_3_2_3_adae_tmrel_socpt);
/*
 * Purpose          : Treatment-emergent study drug-related adverse events resulting in discontinuation of study drug:
 * number of subjects by primary system organ class and preferred term  (SAF)
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : enpjp (Prashant Patel) / date: 10SEP2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_3_2_3_adae_tmrel_socpt.sas (enpjp (Prashant Patel) / date: 09SEP2023)
 ******************************************************************************/

*get data and select only Safety patients;
%load_ads_dat(adae_view, adsDomain = adae, where = trtemfl eq "Y" and areln eq 1 and aeacn eq "DRUG WITHDRAWN"  , adslWhere = &saf_cond.)
%load_ads_dat(adsl_view, adsDomain = adsl, where = &saf_cond, adslVars  =);

%extend_data(indat = adsl_view, outdat = adsl)
%extend_data(indat = adae_view, outdat = adae)
/*Calculate Big "N" for each Phase column*/
%m_adae_bign;

%mtitle;
%incidence_print(
    data        = adae_view1
  , data_n      = adsl_view1
  , var         = aebodsys aedecod
  , class       = aphasen
  , triggercond = aeterm ne ' '
  , total       = NO
  , sortorder   = FREQA
  , evlabel     = Primary System Organ Class#   Preferred Term#   MedDRA Version &v_meddra
  , anytxt      = Number (%) of subjects with at least one such adverse event
  , maxlen      = 40
  , hsplit      = '#@'
)

/* Use %endprog at the end of each study program */
%endprog;
