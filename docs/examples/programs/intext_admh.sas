/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = intext_admh);
/*
 * Purpose          : Intext Medical History tables
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : enpjp (Prashant Patel) / date: 17JAN2024
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/intext_admh.sas (enpjp (Prashant Patel) / date: 30OCT2023)
 ******************************************************************************/


/*Medical history: PTs reported for >=1% of subjects in total group and their associated SOC- number (%) of subjects (SAF)*/

%let mhtable = %intext_find_metadata(title1 = %str(Table: Medical history: number of subjects with findings by primary system organ class and preferred term &SAF_LABEL));


data admhsum;
    set &mhtable.;
    per = input(compress(scan(scan(_t_1,2,"("),1,'%')),best.);
    if per >=1 or _sort1=0;* or _ic_var1 = "";
    ct = input(compress(scan(scan(_t_1,1,"("),1,'%')),best.);
RUN;

proc sort data = admhsum;
    by _ic_var1;
RUN;

data mostfreqPT;
    merge admhsum admhsum(keep = _ic_var1 _ic_var2 ct rename=(ct=soct _ic_var2=_ic_var1_) where = (_ic_var1_="" and _ic_var1 ne ""));
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

%let mh_enum = %intext_get_enumeration(meta_file = &mhtable.);

title1 "Table: Medical history: PTs reported for >=1% of subjects in total and their associated SOC - ";
title2 "<cont>number (%) of subjects &SAF_LABEL";
footnote1 "Source: &mh_enum.";

%datalist(
     data   = mostfreqPT
   , var    = _levtxt _t_1 _t_2 _t_3
   , hsplit = '@#'
   , label  = no
   , maxlen = 50);

%endprog;

**************************************************************;
/*Table (D) 3-2: Medical history: 10 most frequent PTs in each treatment group - number (%) of subjects (analysis set)*/


%let mhtable = %intext_find_metadata(title1 = %str(Table: Medical history: number of subjects with findings by primary system organ class and preferred term &SAF_LABEL));

%let numberPT = 10;

%intext_mostfrequent(
    indat            = &mhtable
  , outdat           = mostfreqPT
  , var_primary      = _ic_var1
  , var_secondary    = _ic_var2
  , number_secondary = &numberPT.
)

data mostfreqPT;
    set mostfreqPT;
    label _levtxt=  "Preferred Term#   MedDRA Version &v_meddra"  ;
RUN;

%let mh_enum = %intext_get_enumeration(meta_file = &mhtable.);

title1 "Table: Medical history: &numberPT. most frequent PTs in each treatment group - number (%) of subjects &SAF_LABEL";
footnote1 "Source: &mh_enum.";

%datalist(
     data   = mostfreqPT
   , var    = _levtxt _t_1 _t_2
   , hsplit = '@#'
   , label  = no
   , maxlen = 50);

%endprog;
