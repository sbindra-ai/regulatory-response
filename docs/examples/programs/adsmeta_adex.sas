/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/Pool  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
  %iniprog(name = adsmeta_adex);
/*
 * Purpose          : create ADEX metadata specification
 * Programming Spec :
 * Validation Level : 1 - verification by review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egcts (Shruti Natekar) / date: 28JUL2022
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : gmrpb (Fiona Yan) / date: 08MAY2023
 * Reason           : remove ATPTREF, TRTPN
 ******************************************************************************/

%create_domain_meta(
    domain = ADEX
  , vars   = EXSEQ APHASE ASTDT AENDT ASTDY AENDY PARAMCD PARCAT1 PARCAT2 PARAMTYP AVAL AVALC AVALCAyN TRTAN
             ICE01FL ICEREAS
);



%endprog;
