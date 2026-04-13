/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = i_8_2_1_4_2_mq_tp   );
/*
 * Purpose          : Tipping point analysis for change from baseline in MENQOL total score -
 *                    MMRM analysis <<at Week 12>> (FAS)
 * Programming Spec :
 * Validation Level : 2 - Double programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 27NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/i_8_2_1_4_2_mq_tp.sas (sgtja (Katrin Roth) / date: 03JUL2023)
 ******************************************************************************/
/* Changed by       : sgtja (Katrin Roth) / date: 20DEC2023
 * Reason           : extended number of steps
 ******************************************************************************/

/*<copied from i_8_2_1_1_1_hfss_mmrm.sas*/

/*****************************
 *Data step
 ****************************/

%LET timep = 40 80 120 ;

%m_anal_datastep_menqol(adqs, "MENB999",&timep,anal);

/*****************************
 *Multiple imputation
 ****************************/
%put  &study.;
%m_mi_menqol(anal,500, &study.,anal_imp);

/*************************************************************/
/********************* Analysis ******************************/
/*************************************************************/


/*?new part*/
/*<each imputed value in the elinzanetant arm that occurs in the
time frame of an ICE would have a value of "delta" added to it*/
/*******************************************************************************
 *Step 3 - adding deltas
 **************************************************************************/

*merging step1 and step2 datasets, to identify the values that were imputed in step2 (ie those that need shift);
data step1a;
    set step_1;
    rename Week_4=Week4a Week_8=Week8a Week_12=Week12a;
    keep _imputation_ usubjid paramcd Week_4 Week_8 Week_12;
RUN;

proc sort data=step_2; by _imputation_ usubjid paramcd; run;
proc sort data=step1a; by _imputation_ usubjid paramcd; run;
data step3;
    merge step1a step_2;
    by _imputation_ usubjid paramcd;
    IF . < Week_4 < 0 then Week_4=0; *If imputed values are negative, setting those to 0* ;
    IF . < Week_8 < 0 then Week_8=0; *If imputed values are negative, setting those to 0* ;
    IF . < Week_12 < 0 then Week_12=0; *If imputed values are negative, setting those to 0* ;

RUN;



*increasing delta until p-value non-significant (at alpha=0.025);
*start with 0 (=original analysis), go in steps of 0.5 until probt_1 in estim_tot is >0.025;

%m_tp_menqol(datain=step3, delta=0)
%m_tp_menqol(datain=step3, delta=0.5)
%m_tp_menqol(datain=step3, delta=1)
%m_tp_menqol(datain=step3, delta=1.5)
%m_tp_menqol(datain=step3, delta=2)
/*%m_tp_menqol(datain=step3, delta=2.5)*/

OPTIONS NOMPRINT;

data __estim_tp_all;
    length col1 col2 col3 col4   $100.  week $20. ;
    set estim_tot_0 estim_tot_05 estim_tot_1 estim_tot_15 estim_tot_2;* estim_tot_25;
    by scenario;
    col1 = Strip(scenario) ;

    col2 = Strip(Put (estimate , 12.2)) ;
    col3 = Strip(Put (Stderr, 12.2)) ;
    col4  = cats (put(LCLMean , 12.2 ) , ',' , put(UCLMean , 12.2 )  );

   if Index (label , 'Week 4') gt 0 then do ; week = "Week 4"  ;weekn = 4; end;
   if Index (label , 'Week 1') gt 0 then do ; week = "Week 1"  ;weekn = 1; end;
   if Index (label , 'Week 12') gt 0 then do; week = "Week 12"  ;weekn = 12; end;

 if week in (  'Week 12' ) ;
   FORMAT probt_1 pvalue6.4;
   Label Col1 = "Scenario"
         Col2 = "Difference of LS-Means"
         col3 = "Standard error"
         col4  = "95% CI for Difference"
         probt_1 = "p-value (one-sided)"  ;
RUN;


/*************************************************************/
/********************* Output   ******************************/
/*************************************************************/

/*output requires the following columns (available from estim_tot)
1. scenario (Elinzanetant120mg+delta and Placebo+0);
2. Difference of LS-Means
3. SE
4. 95% CI for difference
5. one-sided p-value
*/



proc sort data=__estim_tp_all  out = __estim_tp_vis4 ;
   by label week scenario ;
RUN;

proc sort data=__estim_tp_all  out = tby (keep =  week weekn) Nodupkey  ;
  by weekn ;

RUN;


**********************************************;
*save dataset in tlfmeta for use in validation;
***********************************************;
data tlfmeta.mq_estim_tp_all;
    set __estim_tp_all;
RUN;


/*************************************************************/
/********************* Output   ******************************/
/*************************************************************/

%mtitle ;

%datalist(
    data = __estim_tp_vis4
    , by = shift label week weekn scenario
    , tablesby = tby
  , var  =  col1 col2 col3 col4  probt_1
  , order  = shift label week weekn scenario

);

%endprog;