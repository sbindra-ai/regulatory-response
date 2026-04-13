/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = adsmeta_adsv);
/*
 * Purpose          : Study specific updates to ADSV metadata
 * Programming Spec :
 * Validation Level : 1
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gmrpb (Fiona Yan) / date: 19MAY2023
 * Reference prog   :
 ******************************************************************************/
%create_domain_meta(
    domain = ADSV
  , vars   = AVISITN ASTDT AENDT SVSEQ SVPRESP SVOCCUR
);


%endprog;
