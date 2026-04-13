/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = adsmeta_adae);
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
 * Author(s)        : gkbkw (Ashutosh Kumar) / date: 05SEP2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/adsmeta_adae.sas (gkbkw (Ashutosh Kumar) / date: 05SEP2023)
 ******************************************************************************/

%create_domain_meta(
    domain = ADAE
  , vars   = AESEQ AETERM AEDECOD AEBODSYS ASEVN AESER AESREAS AEACN AEACNOTH ARELN AEOUT AESCONG AESDTH AECONTRT
             AERELPR ASTDT AENDT ADURN ASTDY AENDY TRTEMFL PREFL  POSTFL ASSINY APHASE ASTDTF AENDTF CQzzCD AESSINY
);



%endprog;