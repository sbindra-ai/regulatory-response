/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_1_1_addv_sbj_imppd);
/*
 * Purpose          : Number of subjects with important protocol deviations (all randomized subjects)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : enpjp (Prashant Patel) / date: 20SEP2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_1_1_addv_sbj_imppd.sas (enpjp (Prashant Patel) / date: 09SEP2023)
 ******************************************************************************/
%load_ads_dat(adsl_view, adsDomain = adsl, where = &rand_cond.)
%load_ads_dat(dvimp_view, adsDomain = addv, where = idreqimd ne ".", adslWhere = &rand_cond.);

%extend_data(indat = adsl_view, outdat = adsl)
%extend_data(indat = dvimp_view, outdat = addv)

data final;
  set dvimp_view;
reason=upcase(substr(dvdecod,1,1))||lowcase(substr(dvdecod,2));

RUN;
%mtitle;
%incidence_print(
    data        = final
  , data_n      = adsl_view
  , var         = reason
  , class       = &TREAT_ARM_P
  , triggercond = dvterm ne ' '
  , misstext    = Missing
  , sortorder   = FREQC
  , evlabel     = Protocol Deviation Category
  , anytxt      = Subjects with any important deviation
)

/* Use %endprog at the end of each study program */
%endprog;