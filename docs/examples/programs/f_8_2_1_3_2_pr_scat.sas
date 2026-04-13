/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = f_8_2_1_3_2_pr_scat  );
/*
 * Purpose          : Scatterplot of residuals and predicted values from MMRM on change from baseline in mean daily severity of moderate to severe hot flashes (FAS)
 * Programming Spec :
 * Validation Level : 1 - Validation by review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 28NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/f_8_2_1_3_2_pr_scat.sas (emvsx (Phani Tata) / date: 06SEP2023)
 ******************************************************************************/


%load_ads_dat(adqs_view  , adsDomain = adqs  ,
             adslWhere =    &fas_cond ,
             adslVars          = usubjid  ,
             where =  paramcd='PSDSB999' AND avisitn IN (10 40 80 120) ,
             keep = usubjid paramcd  avisitn aval base chg   anl01fl
              );
%load_ads_dat(adsl_view , adsDomain = adsl ,
              where =  &fas_cond ,
              keep  = usubjid fasfl trt01pn region1n );


%extend_data(indat = adqs_view , outdat = adqs )
%extend_data(indat = adsl_view  , outdat = adsl) ;


DATA hfdd;
    MERGE adsl (in=a) adqs;
    BY usubjid;
    IF a;
RUN;


%LET classvar = usubjid trt01pn region1n avisitn ;
%LET xvar = base trt01pn region1n avisitn trt01pn*avisitn base*avisitn ;

OPTIONS MPRINT;
%m_mmrm(hfdd,,&classvar,chg,&xvar,un,lsmeans,estim,pred);quit;
OPTIONS NOMPRINT;

data pred;
    set pred;
    format pred 12.2;
RUN;
*************************************************************;
********************* Plots   *******************************;
**********************************************************;

%mtitle ;

%ScatterPlot(
    data     = pred
    , xvar     = pred
    , yvar     = studentresid
    , xlabel   = Predicted values
    , ylabel   = Conditional studentized residuals
    , yrefline = 0
    , title_ny = No
);




%endprog();
