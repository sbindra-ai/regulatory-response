/*******************************************************************************
 * Bayer AG
 * Study            :  
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_4_1_subgrp_hf);
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
 * Author(s)        : erjli (Yosia Hadisusanto) / date: 10NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/t_8_4_1_subgrp_hf.sas (eokcw (Vijesh Shrivastava) / date: 22SEP2023)
 ******************************************************************************/



/** HFDB998 region **/

%m_mean_chg_subgrp(
    param    = %str(HFDB998)
  , ads      = %str(adqshfss)
  , subgrp   = %str(REGION1N)
  , pop_label1= %str(by region &fas_label)
  , pop      = %str(&fas_cond.)
)
;

/** HFDB998 race **/


%m_mean_chg_subgrp(
    param    = %str(HFDB998)
   , ads      = %str(adqshfss)
  , subgrp   = %str(RACE)
  , pop_label1= %str(by race &fas_label)
  , pop      = %str(&fas_cond.)
)
;


/** HFDB998 ethnicity **/

%m_mean_chg_subgrp(
    param    = %str(HFDB998)
   , ads      = %str(adqshfss)
  , subgrp   = %str(ETHNIC)
  , pop_label1= %str(by Ethnicity &fas_label)
  , pop      = %str(&fas_cond.)
)
;

/** HFDB998 BMI **/


%m_mean_chg_subgrp(
    param    = %str(HFDB998)
   , ads      = %str(adqshfss)
  , subgrp   = %str(BMIGR1N)
  , pop_label1= %str(by BMI &fas_label)
  , pop      = %str(&fas_cond.)
)
;

/** HFDB998 smoking history **/


%m_mean_chg_subgrp(
    param    = %str(HFDB998)
   , ads      = %str(adqshfss)
  , subgrp   = %str(SMOKHXN)
  , pop_label1= %str(by Smoking History &fas_label)
  , pop      = %str(&fas_cond.)
)
;

%endprog()
;