/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = i_8_2_1_2_2_shf_tp   );
/*
 * Purpose          : Tipping point analysis for change from baseline in mean daily frequency of
 *                    moderate to severe hot flashes - MMRM analysis-<<at Week 4/ at Week 12 / at Week 1>>
 * Programming Spec : 
 * Validation Level : 2 - Double programming
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 27NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/i_8_2_1_2_2_shf_tp.sas (sgtja (Katrin Roth) / date: 03JUL2023)
 ******************************************************************************/

/*<copied from i_8_2_1_1_1_hfss_mmrm.sas*/

/*****************************
 *Data step
 ****************************/
%LET timep = 10 40 80 120 ;
%m_anal_datastep(adqshfss, "HFDB999",&timep,anal);

/*****************************
 *Multiple imputation
 ****************************/
%put  &study.;
%m_mi(anal,500, &study.,anal_imp);

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
    rename Week_1 = Week1a Week_4=Week4a Week_8=Week8a Week_12=Week12a;
    keep _imputation_ usubjid paramcd Week_1 Week_4 Week_8 Week_12;
RUN;

proc sort data=step_2; by _imputation_ usubjid paramcd; run;
proc sort data=step1a; by _imputation_ usubjid paramcd; run;
data step3;
    merge step1a step_2;
    by _imputation_ usubjid paramcd;
    IF . < Week_1 < 0 then Week_1=0; *If imputed values are negative, setting those to 0* ;
    IF . < Week_4 < 0 then Week_4=0; *If imputed values are negative, setting those to 0* ;
    IF . < Week_8 < 0 then Week_8=0; *If imputed values are negative, setting those to 0* ;
    IF . < Week_12 < 0 then Week_12=0; *If imputed values are negative, setting those to 0* ;
RUN;


*increasing delta until p-value non-significant (at alpha=0.025);
*start with 0 (=original analysis), go in steps of 0.2 until probt_1 in estim_tot is >0.025;
*if not reached after 10 steps, stop;

%m_tp(datain=step3, delta=0)
%m_tp(datain=step3, delta=0.2)
%m_tp(datain=step3, delta=0.4)
%m_tp(datain=step3, delta=0.6)
%m_tp(datain=step3, delta=0.8)
%m_tp(datain=step3, delta=1.0)
%m_tp(datain=step3, delta=1.2)
%m_tp(datain=step3, delta=1.4)
%m_tp(datain=step3, delta=1.6)
%m_tp(datain=step3, delta=1.8)
%m_tp(datain=step3, delta=2.0)


OPTIONS NOMPRINT;

data __estim_tp_all;
    length col1 col2 col3 col4   $100.  week $20. ;
    set estim_tot_0 estim_tot_02 estim_tot_04 estim_tot_06 estim_tot_08 estim_tot_10
        estim_tot_12 estim_tot_14 estim_tot_16 estim_tot_18 estim_tot_20;
    by scenario;
    col1 = Strip(scenario) ;

    col2 = Strip(Put (estimate , 12.2)) ;
    col3 = Strip(Put (Stderr, 12.2)) ;
    col4  = cats (put(LCLMean , 12.2 ) , ',' , put(UCLMean , 12.2 )  );

    if Index (label , 'Week 4') gt 0 then do ; week = "Week 4"  ;weekn = 4; end;
    if Index (label , 'Week 1') gt 0 then do ; week = "Week 1"  ;weekn = 1; end;
    if Index (label , 'Week 12') gt 0 then do; week = "Week 12"  ;weekn = 12; end;

  if week in ('Week 4' 'Week 12' ) ;
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

proc sort data=__estim_tp_all  out = __estim_tp_vis4 ;
    by label week scenario ;
RUN;

proc sort data=__estim_tp_all  out = tby (keep = week  weekn) Nodupkey  ;
   by weekn ;

RUN;

**********************************************;
*save dataset in tlfmeta for use in validation;
***********************************************;
data tlfmeta.shf_estim_tp_all;
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
