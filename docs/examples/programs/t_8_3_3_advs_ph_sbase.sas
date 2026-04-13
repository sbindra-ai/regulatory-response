/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_3_3_advs_ph_sbase);
/*
 * Purpose          : Physical examination: summary statistics and change from baseline by treatment group by -parameter name, unit (SAF)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 16NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/t_8_3_3_advs_ph_sbase.sas (egavb (Reema S Pawar) / date: 15JUN2023)
 ******************************************************************************/
%load_ads_dat(
    advs_view
  , adsDomain = advs
  , where     = anl01fl = "Y" AND  avisitn NOT IN ( 0 , 900000 ) and paramcd IN ('HIPCIR' 'WAISTHIP' 'WEIGHT' 'WSTCIR')
  , adslWhere = &saf_cond
)
%extend_data(indat = advs_view, outdat = advs)

DATA advs; SET advs; LABEL &treat_var. = 'Treatment';

PROC SORT DATA=advs(KEEP=paramcd) OUT=paramcd NODUPKEY;
     BY paramcd;
RUN;

%MTITLE;

%desc_tab(
    data         = advs
  , var          = aval
  , stat         = n mean std min median max
  , by           = paramcd
  , order        = paramcd
  , class        = avisitn
  , class_order  = avisitn
  , total        = NO
  , round_factor = 0.1
  , vlabel       = no
  , baseline     = ablfl = "Y"
  , compare_var  = chg
  , time         = &treat_var.
  , visittext    = visit
  , baselinetext = baseline at visit
  , subject      = &subj_var.
  , tablesby     = paramcd
  , optimal      = yes
  , maxlen       = 30
  , bylen        = 30
)

/* Use %endprog at the end of each study program */
%endprog;