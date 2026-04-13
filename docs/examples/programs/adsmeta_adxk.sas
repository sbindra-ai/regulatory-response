/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/Pool  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
  %iniprog(name = adsmeta_adxk);
/*
 * Purpose          : create ADXK metadata specification
 * Programming Spec :
 * Validation Level : 1 - verification by review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : epjgw (Roland Meizis) / date: 20JUL2023
 * Reference prog   :
 ******************************************************************************/



%create_domain_meta(
    domain = ADXK
  , vars   = ADSNAME STUDYID USUBJID
             PARAMCD PARAMTYP PARCAT1
             AVISITN ABLFL ADT WEEKDAYN
             AVAL BASE CHG PCHG
);



%endprog;