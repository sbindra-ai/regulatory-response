/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = intext_adae);
/*
 * Purpose          : Intext AE's Tables
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : enpjp (Prashant Patel) / date: 17JAN2024
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/intext_adae.sas (enpjp (Prashant Patel) / date: 30OCT2023)
 ******************************************************************************/


/*TEAEs: 5 most frequent primary SOCs in each treatment group*/
/*with their corresponding 3 most frequent PTs: number (%) of subjects (analysis set);*/

ods escapechar="^";

%let aetable = %intext_find_metadata(title1 = %str(Table: Treatment-emergent adverse events: number of subjects by primary system organ class and preferred term &saf_label));

%let numberSOC = 5;
%let numberPT = 3;

%intext_mostfrequent(
    indat            = &aetable
  , outdat           = combinedSOCandPT
  , var_primary      = _ic_var1
  , var_secondary    = _ic_var2
  , number_primary   = &numberSOC.
  , number_secondary = &numberPT.
)

data sum;
    set combinedSOCandPT;
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


%let enum_src = %intext_get_enumeration(meta_file = &aetable.);

title1 "Table: TEAEs: &numberSOC. most frequent primary SOCs in each treatment group with their corresponding &numberPT. most frequent PTs:";
title2 "<cont> number (%) of subjects &saf_label";
footnote1 "^&super_a.Reported AEs, during the exposure period Week 13 - 26 to Elinzanetant, for the Elinzanetant 120 mg treatment group.";
footnote2 "^&super_b.Reported AEs, during the exposure period to Elinzanetant, for Placebo - Elinzanetant 120 mg treatment group.";
footnote3 "^&super_c.Reported AEs, during the exposure period to Elinzanetant, for both treatment groups.";
footnote4 "Source: &enum_src.";

%datalist(
    data   = mostfreqPT
  , var    = _levtxt _t_1 _t_2 _t_3 _t_4 _t_5
  , maxlen = 25
  , hsplit = '#@'
  , label  = no
);

%endprog;

*****************************************************************;
/*Table (D) 6-2: TEAEs: PTs reported for >=2% of subjects in any treatment group: number (%) of subjects (SAF) */


%let aetable = %intext_find_metadata(title1 = %str(Table: Treatment-emergent adverse events: number of subjects by primary system organ class and preferred term &saf_label));

data adaesum;
    set &aetable.;
    per = input(compress(scan(scan(_t_5,2,"("),1,'%')),best.);
    per1 = input(compress(scan(scan(_t_1,2,"("),1,'%')),best.);
    per2 = input(compress(scan(scan(_t_2,2,"("),1,'%')),best.);
    per3 = input(compress(scan(scan(_t_3,2,"("),1,'%')),best.);
    per4 = input(compress(scan(scan(_t_4,2,"("),1,'%')),best.);
    if (per >=2 or per1>=2 or per2 >=2 or per3>=2 or per4>=2) or _sort1=0;* or _ic_var1 = "";
    ct = input(compress(scan(scan(_t_1,1,"("),1,'%')),best.);
    if _sort1=1 and _labind = 1 then delete;
RUN;

proc sort data = adaesum;
    by _sort1 descending ct _ic_var2;
    label _levtxt=  "Preferred Term#   MedDRA Version &v_meddra"  ;
RUN;

%let enum_src = %intext_get_enumeration(meta_file = &aetable.);

title1 "Table: TEAEs: PTs reported for >=2% of subjects in any treatment group:";
title2 "<cont> number (%) of subjects &saf_label";
footnote1 "^&super_a.Reported AEs, during the exposure period Week 13 - 26 to Elinzanetant, for the Elinzanetant 120 mg treatment group.";
footnote2 "^&super_b.Reported AEs, during the exposure period to Elinzanetant, for Placebo - Elinzanetant 120 mg treatment group.";
footnote3 "^&super_c.Reported AEs, during the exposure period to Elinzanetant, for both treatment groups.";
footnote4 "Source: &enum_src.";

%datalist(
    data   = adaesum
  , var    = _levtxt _t_1 _t_2 _t_3 _t_4 _t_5
  , hsplit = '#@'
  , label  = no
  , maxlen = 25
);

%endprog;

*****************************************************************;
/*Table (D) 6-3: Study drug-related TEAEs: PTs reported for >=2% of subjects in any treatment group: number (%) of subjects (SAF) */

%let aetable = %intext_find_metadata(title1 = %str(Table: Treatment-emergent study drug-related adverse events: number of subjects by primary system organ class and preferred term &saf_label));

data adaesum;
    set &aetable.;
    per = input(compress(scan(scan(_t_5,2,"("),1,'%')),best.);
    per1 = input(compress(scan(scan(_t_1,2,"("),1,'%')),best.);
    per2 = input(compress(scan(scan(_t_2,2,"("),1,'%')),best.);
    per3 = input(compress(scan(scan(_t_3,2,"("),1,'%')),best.);
    per4 = input(compress(scan(scan(_t_4,2,"("),1,'%')),best.);
    if (per >=2 or per1>=2 or per2 >=2 or per3>=2 or per4>=2) or _sort1=0;* or _ic_var1 = "";
    ct = input(compress(scan(scan(_t_1,1,"("),1,'%')),best.);
    if _sort1=1 and _labind = 1 then delete;
RUN;

proc sort data = adaesum;
    by _sort1 descending ct _ic_var2;
    label _levtxt=  "Preferred Term#   MedDRA Version &v_meddra"  ;
RUN;

%let enum_src = %intext_get_enumeration(meta_file = &aetable.);

title1 "Table: Study drug-related TEAEs: PTs reported for >=2% of subjects in any treatment group:";
title2 "<cont> number (%) of subjects &saf_label";
footnote1 "^&super_a.Reported AEs, during the exposure period Week 13 - 26 to Elinzanetant, for the Elinzanetant 120 mg treatment group.";
footnote2 "^&super_b.Reported AEs, during the exposure period to Elinzanetant, for Placebo - Elinzanetant 120 mg treatment group.";
footnote3 "^&super_c.Reported AEs, during the exposure period to Elinzanetant, for both treatment groups.";
footnote4 "Source: &enum_src.";

%datalist(
    data   = adaesum
  , var    = _levtxt _t_1 _t_2 _t_3 _t_4 _t_5
  , maxlen = 25
  , hsplit = '#@'
  , label  = no
);

%endprog;

*****************************************************************;
/*Table (D) 6-4: Serious TEAEs: 10  most frequent PTs in each treatment group: number (%) of subjects (SAF)*/


%let aetable = %intext_find_metadata(title1 = %str(Table: Treatment-emergent serious adverse events: number of subjects by primary system organ class and preferred term &saf_label));

%let numberPT = 9;

%intext_mostfrequent(
    indat            = &aetable
  , outdat           = mostfreqPT
  , var_primary      = _ic_var1
  , var_secondary    = _ic_var2
  , number_secondary = &numberPT.
)

/*create new column text because label has to be changed*/
data mostfreqPT;
    set mostfreqPT;
    text = strip(_levtxt);
    label _levtxt=  "Preferred Term#   MedDRA Version &v_meddra"  ;
RUN;

%let enum_src = %intext_get_enumeration(meta_file = &aetable.);

title1 "Table: Serious TEAEs: &numberPT. most frequent PTs in each treatment group: number (%) of subjects &saf_label";
footnote1 "^&super_a.Reported AEs, during the exposure period Week 13 - 26 to Elinzanetant, for the Elinzanetant 120 mg treatment group.";
footnote2 "^&super_b.Reported AEs, during the exposure period to Elinzanetant, for Placebo - Elinzanetant 120 mg treatment group.";
footnote3 "^&super_c.Reported AEs, during the exposure period to Elinzanetant, for both treatment groups.";
footnote4 "Source: &enum_src.";

%datalist(
    data   = mostfreqPT
  , var    = _levtxt _t_1 _t_2 _t_3 _t_4 _t_5
  , hsplit = '#@'
  , label  = no
  , maxlen = 25
);

%endprog;

*****************************************************************;
/*TEAEs resulting in permanent discontinuation of study drug: PTs reported for >=1% of subjects in any treatment group: number (%) of subjects (SAF)*/

%let aetable = %intext_find_metadata(title1 = %str(Table: Treatment-emergent adverse events resulting in discontinuation of study drug: number of subjects by primary system organ class and preferred term &saf_label));

data adaesum;
    set &aetable.;
    per = input(compress(scan(scan(_t_5,1,"("),1,'%')),best.);
    per1 = input(compress(scan(scan(_t_1,1,"("),1,'%')),best.);
    per2 = input(compress(scan(scan(_t_2,1,"("),1,'%')),best.);
    per3 = input(compress(scan(scan(_t_3,1,"("),1,'%')),best.);
    per4 = input(compress(scan(scan(_t_4,1,"("),1,'%')),best.);
    if (per >=2 or per1>=2 or per2 >=2 or per3>=2 or per4>=2) or _sort1=0;* or _ic_var1 = "";
    ct = input(compress(scan(scan(_t_1,1,"("),1,'%')),best.);
    if _sort1=1 and _labind = 1 then delete;
RUN;

proc sort data = adaesum;
    by _sort1 descending ct _ic_var2;
    label _levtxt=  "Preferred Term#   MedDRA Version &v_meddra"  ;
RUN;


%let enum_src = %intext_get_enumeration(meta_file = &aetable.);

title1 "Table: TEAEs resulting in permanent discontinuation of study drug: PTs reported for >=1% of subjects in any treatment group:";
title2 "<cont> number (%) of subjects &saf_label";
footnote1 "^&super_a.Reported AEs, during the exposure period Week 13 - 26 to Elinzanetant, for the Elinzanetant 120 mg treatment group.";
footnote2 "^&super_b.Reported AEs, during the exposure period to Elinzanetant, for Placebo - Elinzanetant 120 mg treatment group.";
footnote3 "^&super_c.Reported AEs, during the exposure period to Elinzanetant, for both treatment groups.";
footnote4 "Source: &enum_src.";

%datalist(
    data   = adaesum
  , var    = _levtxt _t_1 _t_2 _t_3 _t_4 _t_5
  , maxlen = 25
  , hsplit = '#@'
  , label  = no
);

%endprog;


*****************************************************************;
/*Study drug-related TEAEs resulting in permanent discontinuation of study drug: PTs reported for >=1% of subjects in any treatment group: number (%) of subjects (SAF)*/
%let aetable = %intext_find_metadata(title1 = %str(Table: Treatment-emergent study drug-related adverse events resulting in discontinuation of study drug: number of subjects by primary system organ class and preferred term &saf_label));

data adaesum;
    set &aetable.;
    per = input(compress(scan(scan(_t_5,1,"("),1,'%')),best.);
    per1 = input(compress(scan(scan(_t_1,1,"("),1,'%')),best.);
    per2 = input(compress(scan(scan(_t_2,1,"("),1,'%')),best.);
    per3 = input(compress(scan(scan(_t_3,1,"("),1,'%')),best.);
    per4 = input(compress(scan(scan(_t_4,1,"("),1,'%')),best.);
    if (per >=2 or per1>=2 or per2 >=2 or per3>=2 or per4>=2) or _sort1=0;* or _ic_var1 = "";
    ct = input(compress(scan(scan(_t_1,1,"("),1,'%')),best.);
    if _sort1=1 and _labind = 1 then delete;
RUN;

proc sort data = adaesum;
    by _sort1 descending ct _ic_var2;
    label _levtxt=  "Preferred Term#   MedDRA Version &v_meddra"  ;
RUN;

%let enum_src = %intext_get_enumeration(meta_file = &aetable.);

title1 "Table: Study drug-related TEAEs resulting in permanent discontinuation of study drug: PTs reported for >=1% of subjects in any treatment group:";
title2 "<cont> number (%) of subjects &saf_label";
footnote1 "^&super_a.Reported AEs, during the exposure period Week 13 - 26 to Elinzanetant, for the Elinzanetant 120 mg treatment group.";
footnote2 "^&super_b.Reported AEs, during the exposure period to Elinzanetant, for Placebo - Elinzanetant 120 mg treatment group.";
footnote3 "^&super_c.Reported AEs, during the exposure period to Elinzanetant, for both treatment groups.";
footnote4 "Source: &enum_src.";

%datalist(
    data   = adaesum
  , var    = _levtxt _t_1 _t_2 _t_3 _t_4 _t_5
  , maxlen = 25
  , hsplit = '#@'
  , label  = no
);
%endprog;
