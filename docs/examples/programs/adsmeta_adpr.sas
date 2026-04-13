/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/Pool  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
  %iniprog(name = adsmeta_adpr);
/*
 * Purpose          : create ADPR metadata specification
 * Programming Spec :
 * Validation Level : 1 - verification by review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : eokcw (Vijesh Shrivastava) / date: 30AUG2022
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : gmrpb (Fiona Yan) / date: 26JUL2023
 * Reason           : Update %iniprog parameter and add PRSCAT
 ******************************************************************************/

%create_domain_meta(
    domain = ADPR
  , vars   = PRSEQ PRLNKID PRTRT PRDECOD PRCAT PRSCAT PRPRESP PROCCUR /*PRLOC*/ ASTDT AVISITN ASTDY PRSTAT
             PRREASND PRREASOC
);





%endprog;