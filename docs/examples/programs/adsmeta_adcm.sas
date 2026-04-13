/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/Pool  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
  %iniprog(name = adsmeta_adcm);
/*
 * Purpose          : Study specific updates to ADCM metadata
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : epjgw (Roland Meizis) / date: 11JUL2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/adsmeta_adcm.sas
 ******************************************************************************/
/* Changed by       : gmrpb (Fiona Yan) / date: 06OCT2023
 * Reason           : add VMSFL
 ******************************************************************************/
/* Changed by       : eokcw (Vijesh Shrivastava) / date: 24OCT2023
 * Reason           : Removed PRMEDEF
 ******************************************************************************/


%create_domain_meta(
    domain = ADCM
  , vars   = CMSEQ CMTRT CMATCzz CMCLzz CMSCLzz CMCAT ASTDT ASTDTF AENDT AENDTF PREFL CONFL FUPFL PROHIBFL
             CMENRTPT CMDECOD CMOCCUR ICE01FL ASTDY AENDY ICESTWK ICEENWK VMSFL
);


%endprog()