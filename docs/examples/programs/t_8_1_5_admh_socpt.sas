/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_1_5_admh_socpt);
/*
 * Purpose          : Medical history: number of subjects with findings by primary system organ class and preferred term SAF
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : enpjp (Prashant Patel) / date: 24OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_1_5_admh_socpt.sas (enpjp (Prashant Patel) / date: 09SEP2023)
 ******************************************************************************/

%macro mh(pop_cond1=,subset=,pop_label1=, trtused=);

*get data and select only Safety patients;
%load_ads_dat(
    admh_view
  , adsDomain = admh
  , where     = mhoccur NE 'N'
  , adslVars  = saffl region1n race trt01an
);

%extend_data(indat = admh_view, outdat = admh)

%mtitle;
%incidence_print(
    data        = admh_view (where=(&pop_cond1.))
  , data_n      = ads.adsl (where=(&pop_cond1.))
  , page        = &subset.
  , var         = mhbodsys mhdecod
  , class       = &trtused.
  , triggercond = mhterm ne ' '
  , total       = yes
  , sortorder   = FREQA
  , evlabel     = Primary system organ class#   Preferred term#   MedDRA version &v_meddra
  , anytxt      = Number (%) of subjects with at least one medical history finding
  , hsplit      = '#@'
)

%mend;

%mh(pop_cond1=&saf_cond.,subset=%str(),pop_label1=by overall, trtused=&treat_arm_a.);


/* Use %endprog at the end of each study program */
%endprog();
