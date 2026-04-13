/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = i_8_2_1_1_2_hfss_np);
/*
 * Purpose          : Create non-parametric analyses for change from baseline of HF frequency
 * Programming Spec :
 * Validation Level : 2 - Double programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 28NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/i_8_2_1_1_2_hfss_np.sas (erepe (Claudia Rahner) / date: 20SEP2023)
 ******************************************************************************/


/*****************************
 *Data step
 ****************************/
%LET timep = 10 40 80 120 ;
%m_anal_datastep(adqshfss, "HFDB998",&timep,anal);

/*****************************
 *Multiple imputation
 ****************************/
%put &study.;
%m_mi(anal,500,&study.,anal_imp);

/********************************************************************************
*Calculating of change from baseline values
*********************************************************************************/
 ***********************************************************/
;

    Data step_3;
        set anal_imp;
        rename _name_ = week;
    RUN;

    Proc sort data = step_3;
        by _imputation_ usubjid trt01pn region1n base;
    RUN;

    proc transpose data=step_3 out=t_step_3_a prefix= aval_;
        by _imputation_ usubjid trt01pn region1n base;
        id avisitn;
        var col1;
    RUN;

    proc transpose data=step_3 out=t_step_3_c prefix= chg_;
        by _imputation_ usubjid trt01pn region1n base;
        id avisitn;
        var chg;
    RUN;

    data t_step_3;
        merge t_step_3_a(rename=(aval_10=aval_01 aval_40=aval_04 aval_80=aval_08 aval_120=aval_12)) t_step_3_c(rename=(chg_10=chg_01 chg_40=chg_04 chg_80=chg_08 chg_120=chg_12));
        by _imputation_ usubjid trt01pn region1n base;
        drop _NAME_ _LABEL_;
        rename ;
    RUN;

    **Imputation 1**;


    %macro cmhout  (wk = , imp = , cwk = ) ;
    **Imputation 1**;
    proc sort data = t_step_3;
     by REGION1N ;
    run;

     proc rank data=t_step_3
             (where=(_imputation_= &imp. ))
             nplus1 ties=mean out=m_ranks_imp&imp. ;
                       by REGION1N ;
                       var base chg_01 chg_04 chg_08 chg_12;
                       ranks baserank chg_01_r chg_04_r chg_08_r chg_12_r;
        run;
    proc reg data=m_ranks_imp&imp. NOPRINT;
                   by REGION1N;
                   model chg_&wk._r = baserank;
                   output out=m_residuals_w&wk._&imp. r=resid_w&wk.;
    run;

    proc freq data=m_residuals_w&wk._&imp. ;
                   tables REGION1N*trt01pn*resid_w&wk. / CMH2 noprint;
                   ods output cmh=m_cmhstat_w&wk._&imp.;
    run;


    proc sort data = m_residuals_w&wk._&imp.  ;
        by usubjid ;
    RUN;

    PROC SORT DATA=t_step_3;
        BY _imputation_ trt01pn;
    RUN;


**Imputation 1**;

    proc npar1way data = t_step_3(where=(_imputation_ = &imp. ))
                          HL(REFCLASS="Placebo - Elinzanetant 120mg") NOPRINT;
                   class trt01pn;
                   var &cwk. ;
                   output out=m_HL_w&wk._&imp.;
    run;

    %mend;

    %macro imp (imp =  ) ;

        %cmhout (imp =  &imp.  ,  wk =  01  , cwk = chg_01 ) ;
        %cmhout (imp =  &imp.  ,  wk =  04  , cwk = chg_04 ) ;
        %cmhout (imp =  &imp.  ,  wk =  08  , cwk = chg_08 ) ;
        %cmhout (imp =  &imp.  ,  wk =  12  , cwk = chg_12) ;

            Data M_residuals_all_&imp. ;
                merge M_residuals_w01_&imp.
                      M_residuals_w04_&imp. (keep=usubjid resid_w04)
                      M_residuals_w08_&imp. (keep=usubjid resid_w08)
                      M_residuals_w12_&imp. (keep=usubjid resid_w12);
                by usubjid;
                imputation = &imp.;
            RUN;

            Data m_CMHSTAT_all_&imp.;
                set  m_cmhstat_w01_&imp.
                     m_CMHSTAT_w04_&imp.
                     m_CMHSTAT_w08_&imp.
                     m_CMHSTAT_w12_&imp. ;
                imputation = &imp.;

            RUN;


            Data m_HL_all_&imp.;
                set  m_HL_w01_&imp.
                     m_HL_w04_&imp.
                     m_HL_w08_&imp.
                     m_HL_w12_&imp. ;
                imputation = &imp.;

            RUN;


        proc datasets library=work nolist;
            delete  M_residuals_w01_&imp. M_residuals_w04_&imp. M_residuals_w08_&imp. M_residuals_w12_&imp.
                    m_cmhstat_w01_&imp. m_cmhstat_w04_&imp. m_cmhstat_w08_&imp. m_cmhstat_w12_&imp.
                    m_HL_w01_&imp. m_HL_w04_&imp. m_HL_w08_&imp. m_HL_w12_&imp.
                   ;
        quit;

%MEND;


    proc sort  data = t_step_3 out = impu ( keep = _imputation_  ) nodupkey  ;
        by _imputation_ ;
     *    where _imputation_  <= 5 ;
    RUN;

    data _null_;
        set impu  ;
        call execute ('%imp (imp ='||_imputation_ ||')');
    run;

    Data M_residuals_all;
        set M_residuals_all_: ;
            by imputation ;
    RUN;


    Data  m_HL_all;
        set m_HL_all_: ;
            by imputation ;
    RUN;

    Data m_CMHSTAT_all;
         set m_CMHSTAT_all_: ;
             by imputation ;
    RUN;

    proc datasets library=work nolist;
        delete   m_CMHSTAT_all_:   m_HL_all_:  M_residuals_all_:  ;
               ;
    quit;

***Normalizing transformation***;

/*Before combining the results of the CMH test using Rubin's rule, a*/
/*normalizing transformation using the Wilson-Hilferty transformation as*/
/*described in Ratitch, Lipkovich et al. (2013) will be applied.*/

Data  m_CMHSTAT_normtrans;
    set m_CMHSTAT_all;
    st_cmh = (((value/df)**(1/3))-(1-(2/(9*df)))) / (sqrt(2/(9*df)));
    cmh_stderr = 1;
RUN;

/*******************************************************************************
 *Step 4 - Combine results with Rubin's rule
 *******************************************************************************/

/* standardized CMH, CMH test */
PROC SORT DATA=m_CMHSTAT_normtrans ;
    BY table imputation; RUN;
PROC MIANALYZE DATA=m_CMHSTAT_normtrans(where=(statistic=2));
    BY table;
    MODELEFFECTS st_cmh;
    STDERR cmh_stderr;
ODS OUTPUT ParameterEstimates=m_estim_tot;
RUN;


/* HL estimates */
PROC SORT DATA=m_HL_all;
    BY _VAR_ imputation; RUN;
PROC MIANALYZE DATA=m_HL_all ;
    BY _VAR_;
    MODELEFFECTS _HL_;
    STDERR E_HL;
ODS OUTPUT ParameterEstimates= m_HL_est_tot;
RUN;


/** Divide two-sided p-Value by 2 to get one-sided p-value ;*/
*We will use two-sided p-values;
DATA m_estim_tot;
    SET m_estim_tot;
   /* IF tValue < 0 THEN*/ Probt_1 = Probt;
/*    ELSE Probt_1 = 1-Probt;*/
    FORMAT probt_1 pvalue6.4;
    LABEL probt_1='2-sided p-value';
RUN;


/*Calculate n*/


proc sort data=anal;by usubjid trt01pn region1n base;run;
proc transpose data=anal OUT=anal_trans ;
    by usubjid trt01pn region1n base;
    var Week_1 Week_4 Week_8 Week_12;
RUN;

DATA anal_trans;
    SET anal_trans;
    IF _name_='Week_1' THEN avisitn=10;
    ELSE IF _name_='Week_4' THEN avisitn=40;
    ELSE IF _name_='Week_8' THEN avisitn=80;
    ELSE IF _name_='Week_12' THEN avisitn=120;

    rename col1=aval;
run;

PROC SQL;
    CREATE TABLE subjn (where = (avisitn ^= 80) ) AS
    SELECT COUNT(usubjid) as n,avisitn,trt01pn, 1 as Row
    FROM anal_trans WHERE aval is not null and avisitn in (10, 40 , 120) /*12Sep2023 KL added where statement*/
    GROUP BY trt01pn,avisitn
    order by avisitn , trt01pn ;

    select count(usubjid) into : trtarm1 SEPARATED by "  "
               from adsl
               where trt01pn = 100
               group by trt01pn ;

        select count(usubjid) into : trtarm2 SEPARATED by "  "
               from adsl
               where trt01pn = 101
               group by trt01pn ;
        %put &trtarm1 &trtarm2 ;

QUIT;

proc transpose data = subjn out = _line0t  Prefix = col ;
    by   avisitn Row ;
    var n ;
    id trt01pn ;
    format trt01pn ;
RUN;

data _line0t;
    length col_100 col_101 $40 ;
    set _line0t;
    col_100 = strip(Put(col100 , 4.)) ;
    col_101 = strip(Put(col101 , 4.)) ;
RUN;
data _line23 ;
    length /*col2*/ est_std ci  $100;
    set m_HL_est_tot;
    Row  = 2 ;
    est_std = cats( put(estimate,12.3)) ||' (' ||cats(put(StdErr,12.3)||')' ) ;
    ci = cats(put(LCLMean,12.3)) || ', '|| cats(put(UCLMean,12.3)) ;
    if _var_ in ('chg_01') then avisitn = 10 ;
    if _var_ in ('chg_04') then avisitn = 40 ;
    if _var_ in ('chg_12')  then avisitn = 120  ;

    if _var_ in ( 'chg_01' , 'chg_04' ,'chg_12'  ) ;
    keep  /*col2*/ est_std  ci _var_  avisitn Row ;
RUN;
proc transpose data = _line23 out = _line23t  ;
    by   avisitn Row ;
    var est_std ci ;

RUN;

data _line4 ;
    length _name_ $100 ;
    set m_estim_tot ;
    _name_  = "p-value (two-sided alternative)";

    col1  =  put (probt_1, pvalue6.4)  ;
    Row = 4 ;
    if table in ('Summary for TRT01PN * resid_w04')   then avisitn = 40 ;
    if table in ('Summary for TRT01PN * resid_w12')  then avisitn = 120  ;

    if table in ('Summary for TRT01PN * resid_w01')   then avisitn = 10 ;
    if table in ('Summary for TRT01PN * resid_w08')  then avisitn =  80  ;

    if avisitn in (10,40 ,120) ;
    keep     avisitn col1   Row  ;
RUN;
data _all2 ;
    length /*col*/  col0  $100 ;
    set _line0t  _line23t _line4;;
    if _name_  = 'n' then Col0  = "n";
    if _name_  = 'est_std' then Col0  = "Hodges-Lehmann estimate (SE)";
    if _name_  = 'ci' then Col0  = "95% CI for Hodges-Lehmann estimate";
    if Row = 4             then Col0  = "p-value (two-sided alternative)";

    if avisitn = 10 then avisitn = 1;
    if avisitn = 40 then avisitn = 2;
    if avisitn = 120 then avisitn = 4;

    Label avisitn = "Time"
          col0    =  "Statistics"
          col1    =  "Elinzanetant 120mg vs. Placebo"
         col_100 = "Elinzanetant 120mg (N= &trtarm1.)"
         col_101 = "Placebo - Elinzanetant 120mg (N= &trtarm2.)" ;
    format avisitn _weekf.;
RUN;


%mtitle ;

%datalist(
    data     = _all2
  , by       = avisitn
  , var      = col0  col_100 col_101 col1
  , order    = row
  , freeline = avisitn
  , together = avisitn
  , split =  *

)

%endprog();

