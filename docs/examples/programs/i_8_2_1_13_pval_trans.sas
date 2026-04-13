/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = i_8_2_1_13_pval_trans   );
/*
 * Purpose          : Transformation of P-Value data as required for R programs
 * Programming Spec : 
 * Validation Level : 1 - Validation by review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 27NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/i_8_2_1_13_pval_trans.sas (emvsx (Phani Tata) / date: 08SEP2023)
 ******************************************************************************/
options Nomprint nomlogic  Notes ;
%macro chg (  out = , st = o2 ,   var=    );
data o2_&out.  ;
    set tlfmeta.estim_tot_&out._&st.     ;
    wk = strip(Scan (time , 2 , ''  )) ;
  keep  Probt_1  wk;
RUN;

proc transpose data = o2_&out.   out =  &cat._&parcat. (Drop = _label_)
               Prefix =  o2_&parcat._&cat._pval_;
    var Probt_1;
    id wk ;
RUN;

data  &cat._&parcat. ;
    set  &cat._&parcat. ;
    *keep _name_  o2_&parcat._pval_&var.   o2_&parcat._pval_&var.1;
    keep _name_  &var.;
RUN;
%MEND;


**********************************;
**Macro "CAT" merges in all datasets coming from chg macro *;
**********************************;

%macro cat (cat  , parcat =    ) ;
    data  p_val_&cat. ;
        merge  &cat._: ;
        by _name_;
    RUN;

    data   tlfmeta.p_val_&cat. ;
        retain
               o2_hffreq_&cat._pval_4
               o2_hffreq_&cat._pval_12
               o2_&parcat._&cat._pval_4
               o2_&parcat._&cat._pval_12
               o2_pr_&cat._pval_12
               o2_hffreq_&cat._pval_1
               o2_mq_&cat._pval_12;

        set   p_val_&cat. ;;
 drop _name_ ;
run;

/*proc datasets lib = work   kill ;*/
/*   * delete   &cat._: p_val_:  ;*/
/*    quit;*/
RUN;
%MEND;

***************************************************;
**<Overview of testing of statistical hypotheses from Main analysis data>******;
***************************************************;
%let  cat = main;
%let  parcat = hffreq  ;
%chg (out = &parcat._&cat.    ,
      var = %str(o2_&parcat._&cat._pval_1 o2_&parcat._&cat._pval_4  o2_&parcat._&cat._pval_12 )       );

%let  parcat = hfss ;
%chg (out = &parcat._&cat.     ,
           var = %str(o2_&parcat._&cat._pval_4  o2_&parcat._&cat._pval_12) );

%let  parcat = pr ;
%chg (out = &parcat._&cat.       ,
      var = %str(o2_&parcat._&cat._pval_12  ) );

%let  parcat = mq ;
%chg (out = &parcat._&cat.       ,
      var = %str(o2_&parcat._&cat._pval_12  ) );

%cat (main  , parcat = hfss );

***************************************************;
**<Overview of testing of statistical hypotheses for  first supplementary estimand>******;
***************************************************;
%let  cat = sup1;
%let  parcat = hffreq  ;

%chg (out = &parcat._&cat.    ,
      var = %str(o2_&parcat._&cat._pval_1 o2_&parcat._&cat._pval_4  o2_&parcat._&cat._pval_12 )       );

%let  parcat = shf ;
%chg (out = &parcat._&cat.     ,
           var = %str(o2_&parcat._&cat._pval_4  o2_&parcat._&cat._pval_12) );

%let  parcat = pr ;
%chg (out = &parcat._&cat.       ,
      var = %str(o2_&parcat._&cat._pval_12  ) );


%let  cat = sp1;
%let  parcat = mq ;

%chg (out = &parcat._&cat.       ,
      var = %str(o2_&parcat._&cat._pval_12  ) );
      *rename sp to sup in Menqol dataset*;

data sup1_mq;
    set sp1_mq ;
    rename  o2_mq_sp1_pval_12 = o2_mq_sup1_pval_12;
RUN;

%cat (sup1  , parcat = shf );
***************************************************;
**<Overview of testing of statistical hypotheses for  second supplementary estimand>******;
***************************************************;
%let  cat = sup2;
%let  parcat = hffreq  ;
%chg (out = &parcat._&cat.    ,
      var = %str(o2_&parcat._&cat._pval_1 o2_&parcat._&cat._pval_4  o2_&parcat._&cat._pval_12 )       );

%let  parcat = shf ;
%chg (out = &parcat._&cat.     ,
           var = %str(o2_&parcat._&cat._pval_4  o2_&parcat._&cat._pval_12) );

%let  parcat = pr ;
%chg (out = &parcat._&cat.       ,
      var = %str(o2_&parcat._&cat._pval_12  ) );


%let  cat = sp2;
%let  parcat = mq ;
%chg (out = &parcat._&cat.       ,
      var = %str(o2_&parcat._&cat._pval_12  ) );
      *rename sp to sup in Menqol dataset*;

data sup2_mq;
    set sp2_mq ;
    rename  o2_mq_sp2_pval_12 = o2_mq_sup2_pval_12;
RUN;

%cat (sup2  , parcat = shf );

%endprog();




