/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/Pool  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
  %iniprog(name = adsmeta_admh);
/*
 * Purpose          : Study specific updates to ADMH metadata
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : epjgw (Roland Meizis) / date: 29JUN2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/adsmeta_admh.sas
 ******************************************************************************/

%create_domain_meta(
    domain = ADMH
  , vars   = MHSEQ MHTERM MHBODSYS MHCAT MHDECOD ASTDT AENDT MHENRTPT MHOCCUR
);

%endprog();

