/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name       = if_8_2_1_1_1_hfss   );
/*
 * Purpose          : Change from baseline in mean daily frequency of moderate to severe hot flashes - MMRM analysis - by treatment group (FAS)
 * Programming Spec :
 * Validation Level : 2 - Double programming  ,
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 26NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/if_8_2_1_1_1_hfss.sas (emybb (Kaisa Laapas) / date: 20AUG2023)
 ******************************************************************************/
/* Changed by       : emvsx (Phani Tata) / date: 28FEB2024
 * Reason           : updated Plot Xtype = data as per Clinician  req
 ******************************************************************************/


%let param = %str(mean daily frequency of moderate to severe hot flashes) ;

%let tti1 = %str(Table: Change from baseline in &param. - MMRM analysis - by treatment group &fas_label) ;
%let tti2 = %str() ;

%let tft1 = %str(Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.) ;
%let tft2 = %str(n = number of subjects with observed value for this timepoint and considered in the analysis model.) ;
%let tft3 = %str(In case data is not available for more than 2 days within a week, the value for that particular week was set to missing) ;
%let tft4 = %str(Multiple imputation is used to impute missing values.) ;
%let tft5 = %str(LS-Means = Least Squares Means, SE = Standard Error, MMRM = Mixed Model Repeated Measures, CI = Confidence Interval) ;;


%let xlabel= %str(Time (weeks));
%let ylabel= %str(Change in mean daily frequency);

%let fti1 = %str(Figure: Line plot of LS-Means (MMRM) of change from baseline in &param. by treatment group &fas_label) ;
%let fti2 = %str() ;

%let fft1 = %str(Figure describes the time course of LS-Means +/- SE based on the estimates of the MMRM analysis.) ;
%let fft2 = %str(Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks.) ;
%let fft3 = %str(LS-Means = Least Squares Means, SE = Standard Error, MMRM = Mixed Model Repeated Measures) ;


/*****************************
 *Data step
 ****************************/

%LET timep = 10 40 80 120 ;
%m_anal_datastep(adqshfss, "HFDB998",&timep,anal);

/*****************************
 *Multiple imputation
 ****************************/
%put  &study.;
%m_mi(anal,500,&study.,anal_imp);

/*****************************
 *Analysis
 ****************************/
%LET byvar = _imputation_;
%LET classvar = usubjid trt01pn region1n avisitn ;
%LET xvar = base trt01pn region1n avisitn trt01pn*avisitn base*avisitn ;

OPTIONS MPRINT;
%m_mmrm(anal_imp,&byvar,&classvar,chg,&xvar,un,lsmean,estim,pred);
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

%m_mmrm_rubin (estim  , lsmean, hffreq_main );

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
RUN;

/*************************************************************/
/********************* Output   ******************************/
/*************************************************************/

 %set_titles_footnotes(
         tit1 = &tti1.
     ,   tit2 = &tti2.
     ,   ftn1 = &tft1
     ,   ftn2 = &tft2
     ,   ftn3 = &tft3
     ,   ftn4 = &tft4
     ,   ftn5 = &tft5
  );

%datalist(
    data     = final
  , by       = row row1
  , var      = Col01  comment col_100 col_101 col1
  , order    = row row1
  , freeline = row
  , together = row
  , split =  *
)

/*************************************************************/
/********************* Output   ******************************/
/*************************************************************/

%set_titles_footnotes(
      tit1 = &fti1
  ,   tit2 = &fti2
  ,   ftn1 = &fft1
  ,   ftn2 = &fft2
  ,   ftn3 = &fft3
);

%MeanDeviationPlot(
    data     = lsmean_tot
  , xvar     = avisitn
  , yvar     = estimate
  , class    = trt01pn
  , xtype    = data
  , lower_error = se_low
  , upper_error = se_upp
  , xstart   = min
  , xend     = max
  , xlabel   = &xlabel.
  , ylabel   = &ylabel.
  , XOFFSET  = 0.1
  , title_ny = No
  , yend     = 0
  ,LEGENDTITLE = "Treatment group"
);


%endprog();
