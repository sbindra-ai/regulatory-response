/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = adsmeta_adqshfss);
/*
 * Purpose          : create ADQS metadata specification for HFDD and sleepiness scale
 * Programming Spec :
 * Validation Level : 1 - verification by review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gmrpb (Fiona Yan) / date: 26JUL2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/adsmeta_adqshfss.sas (gmrnq (Susie Zhang) / date: 01MAY2023)
 ******************************************************************************/
/* Changed by       : gmrpb (Fiona Yan) / date: 04JAN2024
 * Reason           : drop ICEDSSRS
 ******************************************************************************/

%create_domain_meta(
    domain = ADQSHFSS
  , vars   = QSSEQ PARAMCD AVAL AVALC CRITy CRITyFL AVISITN ABLFL BASE CHG PCHG ADT ADY PARAMTYP PARCAT1 ATPTN ANLzzFL ICEDSRS ICEINTRS
);

%endprog;