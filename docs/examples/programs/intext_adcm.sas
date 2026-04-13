/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = intext_adcm);
/*
 * Purpose          : Table (D) 4-1: Concomitant medication: 10 most frequent ATC subclasses  in each treatment
 *                     group with their associated ATC classes- number (%) of subjects (SAF)
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : enpjp (Prashant Patel) / date: 17JAN2024
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/intext_adcm.sas (enpjp (Prashant Patel) / date: 06NOV2023)
 ******************************************************************************/


%let cmtable = %intext_find_metadata(title1 = Table: Concomitant medication: number of subjects &saf_label);

%let numberSUB = 10;

%intext_mostfrequent(
    indat                       = &cmtable
  , outdat                      = combinedATCandSUB
  , var_primary                 = _ic_var1
  , var_secondary               = _ic_var2
  , number_secondary            = &numberSUB.
  , match_corresponding_primary = Y
)

data sum;
    set combinedATCandSUB;
    ct = input(compress(scan(scan(_t_1,1,"("),1,'%')),best.);
RUN;

proc sort data = sum;
    by _ic_var1;
RUN;

data mostfreqPT;
    merge sum sum(keep = _ic_var1 _labind ct rename=(ct=soct _labind=_labind_) where = (_labind_=1));
    by _ic_var1;
RUN;

data mostfreqPT;
    set mostfreqPT ;
    by _ic_var1;
    if not(first._ic_var1 and last._ic_var1) or _sort1=0;
RUN;

proc sort data = mostfreqPT;
    by _sort1 descending soct _ic_var1 _anyev descending ct _ic_var2;
RUN;

%let enum_src = %intext_get_enumeration(meta_file = &cmtable.);

title1 "Table: Concomitant medication: &numberSUB. most frequent ATC subclasses in each treatment group with their associated ATC classes";
title2 "<cont> - number (%) of subjects &saf_label";
footnote1 "Source: &enum_src.";

%datalist(
     data   = mostfreqPT
   , var    = _levtxt _t_1 _t_2
   , hsplit = '@#'
   , label  = no
   , maxlen = 50
);

%endprog;