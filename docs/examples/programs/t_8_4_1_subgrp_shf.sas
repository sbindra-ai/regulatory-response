/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_4_1_subgrp_shf);
/*
 * Purpose          : To create subgroup table
 * Programming Spec : 
 * Validation Level : 1 - verification by review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 16NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/t_8_4_1_subgrp_shf.sas (eokcw (Vijesh Shrivastava) / date: 22SEP2023)
 ******************************************************************************/



/** HFDB999 region **/

%m_mean_chg_subgrp(
    param    = %str(HFDB999)
  , ads      = %str(adqshfss)
  , subgrp   = %str(REGION1N)
  , pop_label1= %str(by region &fas_label)
  , pop      = %str(&fas_cond.)
)
;

/** HFDB999 race **/


%m_mean_chg_subgrp(
    param    = %str(HFDB999)
   , ads      = %str(adqshfss)
  , subgrp   = %str(RACE)
  , pop_label1= %str(by race &fas_label)
  , pop      = %str(&fas_cond.)
)
;


/** HFDB999 ethnicity **/

%m_mean_chg_subgrp(
    param    = %str(HFDB999)
   , ads      = %str(adqshfss)
  , subgrp   = %str(ETHNIC)
  , pop_label1= %str(by ethnicity &fas_label)
  , pop      = %str(&fas_cond.)
)
;

/** HFDB999 BMI **/


%m_mean_chg_subgrp(
    param    = %str(HFDB999)
   , ads      = %str(adqshfss)
  , subgrp   = %str(BMIGR1N)
  , pop_label1= %str(by BMI &fas_label)
  , pop      = %str(&fas_cond.)
)
;

/** HFDB999 smoking history **/


%m_mean_chg_subgrp(
    param    = %str(HFDB999)
   , ads      = %str(adqshfss)
  , subgrp   = %str(SMOKHXN)
  , pop_label1= %str(by Smoking History &fas_label)
  , pop      = %str(&fas_cond.)
)
;

%endprog()
;