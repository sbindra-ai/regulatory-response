/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(
      name       = l_10_2_4_ie_demo
  );
/*
 * Purpose          : Inclusion/exclusion criteria
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gniiq (Mayur Parchure) / date: 13OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/l_10_2_4_ie_demo.sas (gniiq (Mayur Parchure) / date: 13OCT2023)
 ******************************************************************************/

DATA ie_01(KEEP= IETESTCD IETEST iecatn);
     SET sp.TI;
     IF iecat='INCLUSION' THEN iecatn = 1;
     ELSE IF iecat='EXCLUSION' THEN iecatn = 2;
RUN;

PROC SORT DATA=ie_01 NODUPKEY;
     BY IETESTCD IETEST;
RUN;

PROC SORT DATA=ie_01 ;
     BY IECATN IETESTCD;
RUN;

%MTITLE;

%datalist(
     data     = ie_01
   , by       = IECATN IETESTCD
   , order    = IECATN
   , var      = IETEST
   , freeline = IETESTCD
   , maxlen   = 80
   , bylen    = 40
   , optimal = NO)

%endprog()
