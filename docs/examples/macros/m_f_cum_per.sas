
%MACRO  m_f_cum_per(   param1 = paramcd ,
                      param2= parcat1,
                      ads = ,
                      pop =,
                      xtick =
                        )

/ DES = '###Cumulative percent of subjects by change from baseline ###';
/*******************************************************************************
 * Bayer AG
 * Macro rely on: ###choose: TOSCA, initstudy, GMS, GDD, pure SAS###
 *******************************************************************************
 * Purpose          : Produce Cumulative percent of subjects by change from baseline  for the Analysis
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
 * Author(s)        : emvsx (Phani Tata) / date: 20SEP2023
 *******************************************************************************
 * Change History   :
 *
 ******************************************************************************/
/* Changed by       : emvsx (Phani Tata) / date: 29NOV2023
 * Reason           : Updated where condition to use   and ANL04FL = "Y"
 *                    for ADQS and ADQSHFSS
 ******************************************************************************/
/*******************************************************************************
 * Examples         :
     %m_f_cum_per(   param1 = paramcd ,
                      param2= parcat1,
                      ads = ADQS  or ADQSHFSS ,
                      pop =  safety or ITT population
                      )
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
%load_ads_dat(adsl_view   , adsDomain = adsl  , where     =  &pop.  ) ;

data &ads._1 ;
set &ads._view ;
where paramcd = "&param1."
      and parcat1 = "&param2."
      and avisitn in ( 40 , 120 )
      and ANL04FL = "Y"
      ;

if  int(chg) ^ = (chg) then chgc = put(chg , 12.2);
else  chgc = put(chg , 12.);;
drop chg;
run;

data  &ads._1;
    set &ads._1 ;
    chg = Input(strip(chgc) , best. ) ;
    attrib chg label  = "Change from baseline" ;
RUN;


proc sort data =  &ads._1  ;
    by avisitn  &treat_arm_p.;
run;
proc freq data =  &ads._1  ;
 by avisitn  &treat_arm_p.;
 tables chg / outcum out=cdf;
run;

%MTITLE;

%LinePlot(
    data     = cdf
  , xvar     = chg
  , yvar     = cum_pct
  , XTICKLIST = &xtick
  , linetype = step
  , show_scatter = N
  , title_ny   = NO
  , by   = avisitn
  , ylabel    = "Cumulative percent of subjects"
  , class       =   &treat_arm_p.
  , LEGENDTITLE  = Treatment Group
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
%endprog;

%MEND m_f_cum_per;



