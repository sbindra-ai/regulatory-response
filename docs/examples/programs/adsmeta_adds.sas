/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = adsmeta_adds);
/*
 * Purpose          : Study specific updates to ADDS metadata
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gnrty (Ashu Pandey) / date: 28JUL2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/adsmeta_adds.sas (gmrnq (Susie Zhang) / date: 05JUN2023)
 ******************************************************************************/
/* Changed by       : gmrpb (Fiona Yan) / date: 06OCT2023
 * Reason           : ICESREAS
 ******************************************************************************/

%create_domain_meta(
    domain = ADDS
  , vars   = DSSEQ DSTERM DSDECOD DSCAT DSSCAT DSNEXT DSSUBDEC ASTDT APHASE EPOCH ICE01FL ICEREAS ASTDY ICESTWK

);


%endprog;