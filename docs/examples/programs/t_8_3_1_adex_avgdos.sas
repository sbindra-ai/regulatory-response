/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_3_1_adex_avgdos);
/*
 * Purpose          : Treatment dose of Elinzanetant per day by treatment group (FAS/SAF)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : enpjp (Prashant Patel) / date: 10SEP2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_3_1_adex_avgdos.sas (enpjp (Prashant Patel) / date: 09SEP2023)
 ******************************************************************************/
%macro rpt(trtvar=, popu=, poplabel=);

/*Study Drug*/
%load_ads_dat(adsl_view, adsDomain = adsl, where = &&&popu._cond. )
%load_ads_dat(
    adex_view
  , adsDomain = adex
  , where     = paramcd in('ACDDCRF' 'ACDDDRY') and aval ne .
  , adslWhere = &&&popu._cond.
  , adslVars  = saffl fasfl &trtvar.
)

%extend_data(indat = adsl_view, outdat = adsl)
%extend_data(indat = adex_view, outdat = adex)

data adex1;
    set adex_view;
    label aval ="Dose per day (mg)" ;
    label parcat1 ="Treatment Dose" ;
    label aphase  ="Treatment Period";
RUN;

%mtitle;
%desc_freq_tab(
    data           = adex1
  , var            = aval
  , class          = &trtvar.
  , data_n         = adsl_view
  , subject        = usubjid
  , page           = parcat1
  , by             = aphase
  , data_n_ignore  = aphase parcat1
  , total          = NO
  , missing        = yes
  , basepct        = n_class
  , levlabel       = yes
  , stat           = n nmiss mean std min median max
  , round_factor   = 0.1
  , rtf_desc_align = YES
  , order_var      = aphase = "Week 1-12" "Week 13-26" "Overall"
)

%MEND;

%rpt(trtvar=&treat_arm_p., popu=fas, poplabel=&fas_label);
%rpt(trtvar=&treat_arm_a., popu=saf, poplabel=&saf_label);
%rpt(trtvar=&treat_arm_p., popu=slas, poplabel=&slas_label);

/* Use %endprog at the end of each study program */
%endprog;
