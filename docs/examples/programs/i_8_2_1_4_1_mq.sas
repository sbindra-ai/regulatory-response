/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = i_8_2_1_4_1_mq   );
/*
 * Purpose          : MENQOL total score change from baseline - MMRM analysis - by treatment group(FAS)
 * Programming Spec : 
 * Validation Level : 2 - Double programming
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 27NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/i_8_2_1_4_1_mq.sas (emybb (Kaisa Laapas) / date: 13AUG2023)
 ******************************************************************************/


/*****************************
 *Data step
 ****************************/

%LET timep =  40 80 120 ;
%m_anal_datastep(adqs, "MENB999",&timep,anal);

/*****************************
 *Multiple imputation
 ****************************/

%put  &study.;
%m_mi_menqol(anal,500,&study.,anal_imp);

/*****************************
 *Analysis
 ****************************/
%LET byvar = _imputation_;
%LET classvar = usubjid trt01pn region1n avisitn ;
%LET xvar = base trt01pn region1n avisitn trt01pn*avisitn base*avisitn ;

OPTIONS MPRINT;
%m_mmrm_menqol(anal_imp,&byvar,&classvar,chg,&xvar,un,lsmean,estim,pred);
quit;

%let cov=&MMRMStrUsed;
data usedcov;
    print="Covariance structure used: &cov" ;
    label print='';
RUN;

OPTIONS NOMPRINT;


/*Outputting information to .lst*/
title1 "MI procedure - Model information" ;
proc print data = modelinfo0;
RUN;


title1 "Missing Data Patterns before non-monotone imputation " ;
proc print data = misspatt0;
RUN;

title1 "MI procedure - Model information" ;
proc print data = modelinfo1;
RUN;


title1 "Missing Data Patterns after non-monotone imputation " ;
proc print data = misspatt1;
RUN;

title1 "The Mixed Procedure " ;
proc print data = usedcov;
RUN;
title1 ' ';

/*****************************
 *Combining the results
 ****************************/

%m_mmrm_rubin (estim  , lsmean ,  mq_main  );

proc sort data = hfdd
     out = tby (keep = paramcd) nodupkey ;
    by paramcd ;
    where not missing(paramcd);
RUN;

Proc Sql noprint ;
    select count(usubjid) into : trtarm1 SEPARATED by "  "
           from adsl
           where trt01pn = 100
           group by trt01pn ;

    select count(usubjid) into : trtarm2 SEPARATED by "  "
           from adsl
           where trt01pn = 101
           group by trt01pn ;
    %put &trtarm1 &trtarm2 ;


    select paramcd into : paramcd SEPARATED by ""
           from tby
           where not missing(paramcd)
         ;

QUIT;

data final ;
    set t_0 t_l0 t_l2 ;
RUN;
proc sort data  = final ;
    by row row1 ;
RUN;

data final ;
    set final ;
    by row row1 ;
    if row1  = 0 then Col01  = Col0 ;

   Label col_100 = "Elinzanetant 120mg (N= &trtarm1.)"
     col_101 = "Placebo - Elinzanetant 120mg (N= &trtarm2.)"
    Col01  = "Time"
    comment = "Statistics" ;
   if Row  = 12 ;
RUN;

/*************************************************************/
/********************* Output   ******************************/
/*************************************************************/
%MTITLE;

%datalist(
    data     = final
  , by       = row row1
  , var      = Col01  comment col_100 col_101 col1
  , order    = row row1
  , freeline = row
  , together = row
  , split =  *
)
;


%endprog();