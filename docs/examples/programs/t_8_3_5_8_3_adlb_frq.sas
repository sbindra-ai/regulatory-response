/*******************************************************************************
 * Bayer AG
 * Study            : 21810 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 52 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_3_5_8_3_adlb_frq     );
/*
 * Purpose          : Number of subjects by combined hepatic safety laboratory categories relative to baseline
 * Programming Spec : 21810_tlf_v1.0.docx
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emzah (Rakesh Muppidi) / date: 20OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_3_5_8_3_adlb_frq.sas (emvsx (Phani Tata) / date: 30AUG2023)
 ******************************************************************************/

%load_ads_dat(adlb_view, adsDomain = adlb , adslWhere =  &saf_cond )
%load_ads_dat(adsl_view , adsDomain = adsl , where =  &saf_cond )

%extend_data(indat = adlb_view , outdat = adlb )
%extend_data(indat = adsl_view  , outdat = adsl) ;

data adlb ;
    set adlb ;

    if  index(paramcd, "CCRIT") >0 then
    Crit = input(Compress (Paramcd , '' , 'Kd') , 3.);

   if  9 <= Crit <=13     ;
   if avisitn  > 5  then avist = "Post Baseline";
   if avisitn  = 5  then avist = "Baseline";


   format  avalc X_NY.;
   attrib   avalc  label = ""
   AVIST  label = "Time interval"
   Paramcd  label = "Category"   ;

run;

PROC SORT DATA=adlb
     OUT=tby (KEEP= paramcd  paramn parcat1)  nodupkey;
    BY parcat1 paramn ;
RUN;

%MTITLE;

%freq_tab(
    data    = adlb
  , data_n  = adsl
  , var     = avalc
  , subject = &subj_var.
  , by      =  paramn    paramcd
  , total   = NO
  , order   =  paramn
  , class   = &treat_var
  , hlabel  = Yes
  , missing = NO
  , complete  = ALL
 , class_order = 'n' "No" "Yes"
);

%endprog;
