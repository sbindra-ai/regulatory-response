/*******************************************************************************
 * Bayer AG
 * Study            : 21656 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms caused by adjuvant endocrine therapy,
 *   over 52 weeks and optionally for an additional 2 years in women with, or at
 *   high risk for developing hormone-receptor positive breast cancer
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = d_adlb_dili_tab, print2file = N, log2file = Y);
/*
 * Purpose          : Create dataset for ADLB table (only needed for CLO narratives)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : glimy (Victoria Aitken) / date: 04OCT2024
 * Reference prog   : /var/swan/root/bhc/3427080/21656/stat/query02/prod/pgms/d_adlb_dili_tab.sas (ggqct (Jose Diaz) / date: 27FEB2024)
 ******************************************************************************/


proc sort data = ads_act.critall out = clo_subj (keep = studyid usubjid critdt);
    by studyid usubjid;
    where find(cr_list,'Close liver observation');
run;

%create_ads_view(
    adsDomain = adlb
  , outDat    = adlbview
)

data adlb;
    set adlbview ;
    where paramcd in ('HBSAG', 'HAIGMAB','HCAB','HEIGMAB','ANAB', 'ASMOMAB','IGG','CMVIGMAB','EBVCAIGM') and LBSTAT ne "NOT DONE";
RUN;

proc sort data=adlb ;
    by usubjid paramcd;
RUN;

/* only CLO */

data adlb0;
    merge adlb (in=a) clo_subj (in=b);
    by studyid usubjid;
    if a and b;
RUN;

/* select date injury onset */

proc sql;
    create table date_inju  as
           select usubjid, paramcd, min(adt) as max_adt format = date9.
           from adlb0
           where avisitn eq 500000
           group by usubjid, paramcd
           order by usubjid, paramcd
           ;
QUIT;
RUN;

data adlb_dili_tab0;
    merge adlb0 (in=a) date_inju (in=b);
    by usubjid paramcd;
    if a and b;
run;

data adlb_dili_tab;
    length DONE $3 paraml $70;
    set adlb_dili_tab0;
    by usubjid paramcd;

    if adt >= max_adt then DONE = 'YES';
    else if adt < max_adt then delete; *only want done=YES records in the table;

    if not first.paramcd then paramcd = " ";

    if paramcd eq "IGG" then paraml = strip(put(paramcd,$x_lbpar.))||' (Lower limit:'||strip(put(anrlo,best.))||', Upper Limit:'||strip(put(anrhi,best.))||')';
    else paraml = put(paramcd,$x_lbpar.) ;

    keep usubjid paramcd done avalc lbdy adt max_adt paraml;
    where adt >= max_adt;
RUN;

data ads_act.adlb_dili_tab;
    set adlb_dili_tab;
RUN;


%endprog()