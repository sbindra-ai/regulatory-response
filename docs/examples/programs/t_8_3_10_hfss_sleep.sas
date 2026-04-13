/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_3_10_hfss_sleep);
/*
 * Purpose          : Sleepiness scale: summary statistics and change from baseline by treatment group - by parameter name -(SAF)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : epjgw (Roland Meizis) / date: 12DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/t_8_3_10_hfss_sleep.sas (egavb (Reema S Pawar) / date: 14JUN2023)
 ******************************************************************************/

%load_ads_dat(
    adqshfss_view
  , adsDomain = adqshfss
  , where     = AVISITN IN ( 5 10 40 120)
                AND not missing (aval)
                AND ANL04FL="Y"
                AND PARAMCD IN('SLSB0996' 'SLSB0997' 'SLSB0998' 'SLSB0999')
  , adslWhere = &saf_cond
)

%extend_data(indat = adqshfss_view, outdat = adqshfss)

PROC SORT DATA=adqshfss(keep=paramcd) OUT=paramcd NODUPKEY;
     BY paramcd;
RUN;

/* Change treatment label */
data adqshfss;
    set adqshfss;

    attrib &treat_var. label="Treatment";
run;

%MTITLE;

%desc_tab(
    data        = adqshfss
  , var         = aval
  , by          = paramcd
  , order       = paramcd
  , class       = avisitn
  , total       = NO
  , round_limit = 2
  , vlabel      = NO
  , baseline    = ablfl = "Y"
  , compare_var = chg
  , time        = &treat_var.
  , subject     = &subj_var.
  , tablesby    = paramcd
)


/* Use %endprog at the end of each study program */
%endprog;