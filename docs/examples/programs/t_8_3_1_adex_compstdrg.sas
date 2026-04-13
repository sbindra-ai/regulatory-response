/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_3_1_adex_compstdrg);
/*
 * Purpose          : Treatment compliance by study group (SAF)
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : enpjp (Prashant Patel) / date: 10SEP2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_3_1_adex_compstdrg.sas (enpjp (Prashant Patel) / date: 09SEP2023)
 ******************************************************************************/

/*Study Drug*/
%macro rpt(pop = , trt = , poplabel =);

%load_ads_dat(adsl_view, adsDomain = adsl, where = &pop)
%load_ads_dat(
    adex_view
  , adsDomain = adex
  , where     = paramcd in('CMPDRYDR' 'CMPCRFDR') and aval ne . and parcat2 = "by study drug"
  , adslWhere = &pop.
  , adslVars  = saffl fasfl
)

%extend_data(indat = adsl_view, outdat = adsl)
%extend_data(indat = adex_view, outdat = adex)

data adexfinal;
    set adex_view;
    label aval    ="Compliance (%)"
          avalca1n="Categories n (%)"
          parcat1 ="Treatment compliance"
          aphase  ="Treatment period";
RUN;

%mtitle;
%desc_freq_tab(
    data         = adexfinal
  , var          = aval avalca1n
  , class        = &trt.
  , subject      = usubjid
  , page         = parcat1
  , by           = aphase
  , total        = NO
  , class_order  = 1 0
  , missing      = NO
  , levlabel     = yes
  , stat         = n nmiss mean std min median max
  , round_factor = 0.1
  , order_var    = aphase = "Week 1-12" "Week 13-26" "Overall"
)

%MEND;

%rpt(pop=%str(&SAF_COND), trt=trtan, poplabel=&SAF_LABEL);

/* Use %endprog at the end of each study program */
%endprog();
