/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = adsmeta_adfapr);
/*
 * Purpose          : Study specific updates to ADAE metadata
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gkbkw (Ashutosh Kumar) / date: 18AUG2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/adsmeta_adfapr.sas (gkbkw (Ashutosh Kumar) / date: 05JUL2023)
 ******************************************************************************/

%create_domain_meta(
    domain = ADFAPR
  , vars   = FASEQ PARAMCD AVAL AVALC ADT FAEVAL   PARCAT1 PARCAT2 FALAT FAOBJ ANLzzFL AVISITN
             BASE CHG ABLFL FASTAT FAREASND FAEVALID FALNKID FACLSIG DTYPE
);



%endprog;