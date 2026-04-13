
%MACRO  m_f_line_plot(   param1 = paramcd ,
                      param2= parcat1,
                      ads = ,
                      pop =  ,
                      label_x = ,
                      label_y = ,
                      lgtitle =  ,
                      cond =  ,
                      avisvar = n_avsitn ,
                      Xtypeval  = data
                      )

/ DES = '###Line plot of change from baseline###';
/*******************************************************************************
 * Bayer AG
 * Macro rely on: ###choose: TOSCA, initstudy, GMS, GDD, pure SAS###
 *******************************************************************************
 * Purpose          : Produce Box Plot for the Analysis
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * Parameters       :
 *                    param1 :
 *                    param1 :
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Preconditions    :
 *     Macrovar. needed:
 *     Datasets  needed:
 *     Ext.Prg/Mac used:
 * Postconditions   :
 *     Macrovar created:
 *     Output   created:
 *     Datasets created:
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 21SEP2023
 *******************************************************************************
 * Change History   :
 ******************************************************************************/
/* Changed by       : emvsx (Phani Tata) / date: 25SEP2023
 * Reason           : Updated where condition to use   and ANL04FL = "Y"
 *                    for ADQS and ADQSHFSS
 ******************************************************************************/
/* Changed by       : emvsx (Phani Tata) / date: 01FEB2024
 * Reason           : stat  = ARITH_CL95 for  95% confidence interval
 ******************************************************************************/
/* Changed by       : emvsx (Phani Tata) / date: 06MAR2024
 * Reason           : As per Clinical team (Taru,Christian ) request 02/24/2024 to spread visits
  ******************************************************************************/
 /* Changed by       : emvsx (Phani Tata) / date: 06MAR2024
  * Reason           : Regular visits to Hot Flashes data AVISITN
  ******************************************************************************/

/*******************************************************************************
 * Examples         :
   %m_f_line_plot(   param1 = <Paramcd id > ,
                      param2= parcat1,
                      ads = ADQS  or ADQSHFSS ,
                      pop =  safety or ITT population ,
                      label_x = x axis label  ,
                      label_y = y label ,
                      lgtitle = Legend title  );
 ******************************************************************************/
%LOCAL macro mversion _starttime  ;
%LET macro    = &sysmacroname.;
%LET mversion = 1.0;

%spro_check_param(name=param1, type=TEXT)
%spro_check_param(name=param2, type=TEXT)

%IF (%QUOTE(&macro_parameter_error.) EQ %STR(1)) %THEN %RETURN;

%LET _starttime = %SYSFUNC(datetime());
%log(
        INFO
      , Version &mversion started
      , addDateTime = Y
      , messageHint = BEGIN)

%LOCAL l_opts l_notes;
%LET l_notes = %SYSFUNC(getoption(notes));

%LET l_opts = %SYSFUNC(getoption(source))
              %SYSFUNC(getoption(notes))
              %SYSFUNC(getoption(fmterr))
;

OPTIONS NONOTES NOSOURCE NOFMTERR;
*----------------------------------*;
%* Put your macro code here!;
*----------------------------------*;
%load_ads_dat(&ads._view  , adsDomain = &ads. , adslWhere =  &pop. )
%load_ads_dat(adsl_view   , adsDomain = adsl  , where     =  &pop. )

%extend_data(indat = &ads._view , outdat =  &ads. );
%extend_data(indat = adsl_view  , outdat = adsl) ;
**;
data &ads. ;
set &ads. ;
where paramcd = "&param1."
      and parcat1 = "&param2."
      and not missing(chg)
      and ANL04FL = "Y"  ;
if ( 5 <= avisitn <= 260 ) or
   ( 700000 <= avisitn <= 700040 ) ;

attrib  TRT01PN  label = "Treatment" ;
run;
*As per Clinical team (Taru,Christian ) request 02/24/2024 to spread visits *;
data &ads. ;
  set  &ads. ;
     if avisitn = 5 then n_avsitn = 0 ;
     else if avisitn = 600010 then n_avsitn = 261 ;
     else if avisitn = 700000 then n_avsitn = 300 ;
     else if avisitn = 700010 then n_avsitn = 310 ;
     else if avisitn = 700020 then n_avsitn = 320 ;
     else if avisitn = 700030 then n_avsitn = 330 ;
     else if avisitn = 700040 then n_avsitn = 340 ;

     else n_avsitn = avisitn  ;
 format n_avsitn _plotvis. ;
run;

PROC DATASETS LIBRARY=WORK NOLIST;
MODIFY  &ads.  ;
FORMAT chg  9.2;
QUIT;

%MTITLE;

%gral_style(
markers         = CircleFilled
, graphdatadefault = linethickness=2px )

%MeanDeviationPlot(
    data          =  &ads.
  , data_n        = adsl
  , xvar          = &avisvar.
  , yvar          = chg
  , class         = &treat_arm_p.
  , class_order   = &mosto_param_class_order.
  , xtype         = &Xtypeval.
  , xstart        = min
  , xend          = max
  , xlabel        = &label_x
  , ylabel        = &label_y
  , subject       = usubjid
  , title_ny      = No
  , legendtitle   = &lgtitle
  , style         = report2
  , stat          = ARITH_CL95          /* Figure describes the time course of mean and 95% confidence interval */
);

OPTIONS &l_notes.;
%PUT %STR(NO)TE: &macro. - Put your note here;
OPTIONS NONOTES;

%end_macro:;

OPTIONS &l_opts.;
%log(
        INFO
      , Version &mversion terminated.
      , addDateTime = Y
      , messageHint = END)
%log(
        INFO
      , Runtime: %SYSFUNC(putn(%SYSFUNC(datetime())-&_starttime., F12.2)) seconds!
      , addDateTime = Y
      , messageHint = END)

*----------------------------------*;
%MEND m_f_line_plot;




