/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = adsmeta_adqs);
/*
 * Purpose          : create ADQS metadata specification
 * Programming Spec :
 * Validation Level : 1 - verification by review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gmrnq (Susie Zhang) / date: 01AUG2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/adsmeta_adqs.sas (gmrnq (Susie Zhang) / date: 30MAY2023)
 ******************************************************************************/
/* Changed by       : gmrpb (Fiona Yan) / date: 06OCT2023
 * Reason           : drop ICEDSSRS
 ******************************************************************************/

%create_domain_meta(
    domain = ADQS
  , vars   = QSSEQ PARAMCD AVAL AVALC AVALCAyN AVISITN ABLFL BASE CHG PCHG ADT ATM ADY PARAMTYP PARCAT1 PARCAT2
        ATPTN ANLzzFL ICEDSRS ICEINTRS QSSTAT QSGRPID DTYPE
);


%endprog;