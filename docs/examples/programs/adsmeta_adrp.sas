
/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/Pool  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = adsmeta_adrp);
/*
 * Purpose          : create ADRP metadata specification
 * Programming Spec :
 * Validation Level : 1 - verification by review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : eokcw (Vijesh Shrivastava) / date: 23AUG2022
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : gmrpb (Fiona Yan) / date: 27FEB2023
 * Reason           : Update %iniprog parameter
 ******************************************************************************/

%create_domain_meta(
    domain = ADRP
  , vars   = RPSEQ PARAMCD AVAL AVALC AVISITN ADT
);





%endprog;
