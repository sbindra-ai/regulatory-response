/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_4_1_subgrp_pr_isi);
/*
 * Purpose          : To create subgroup table
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 11OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/t_8_4_1_subgrp_pr_isi.sas (egavb (Reema S Pawar) / date: 10OCT2023)
 ******************************************************************************/

/** PSDSB999 Insomnia index **/


%m_mean_chg_subgrp(
    param    = %str(PSDSB999)
   , ads      = %str(adqs)
  , subgrp   = %str(ISICAT)
  , pop_label1= %str(by Insomnia Severity Index (ISI) &fas_label)
  , pop      = %str(&fas_cond.)
)
;


%endprog()
;