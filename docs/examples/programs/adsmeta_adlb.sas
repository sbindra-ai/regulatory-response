/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = adsmeta_adlb);
/*
 * Purpose          : Study specific updates to ADLB metadata
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gkbkw (Ashutosh Kumar) / date: 10AUG2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/adsmeta_adlb.sas (gkbkw (Ashutosh Kumar) / date: 03JUL2023)
 ******************************************************************************/

%create_domain_meta(
    domain = ADLB
  , vars   = LBSEQ PARAMN PARAMCD  AVAL AVALC BASE CHG AVISITN ABLFL ANLzzFL ANRIND TRTEMFL CRITy CRITyFL
             ADT ATM ANRLO ANRHI PARCAT1 PARCAT2  PARAMTYP LBSTAT ADY
);



%endprog;