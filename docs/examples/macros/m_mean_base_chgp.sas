%MACRO m_mean_base_chgp(param1 =,
                     param2= ,
                     ads   =    ,
                     param = ,
                     pop =  ,
                     round = )
/ DES = 'Summary statistics and change from baseline by treatment group';
/*******************************************************************************
 * Bayer AG
 * Macro rely on: ###choose: TOSCA, initstudy, GMS, GDD, pure SAS###
 *******************************************************************************
 * Purpose          : Summary statistics and change from baseline by treatment group
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
 * Author(s)        : emvsx (Phani Tata) / date: 25JUL2022
 *******************************************************************************
 * Change History   :
 ******************************************************************************/
/* Changed by       : emvsx (Phani Tata) / date: 08AUG2022
 * Reason           : updated the header
 ******************************************************************************/
/* Changed by       : emvsx (Phani Tata) / date: 29NOV2023
 * Reason           : Updated where condition to use   and ANL04FL = "Y"
 *                    for ADQS and ADQSHFSS
 ******************************************************************************/

/*******************************************************************************
 * Examples         :
   %m_mean_base_chg(param1 = paramcd ,
                     param2= parcat1,
                     ads   = <dataset>   ,
                     param =  <paramcd or Parcat1 used for title>,
                     pop =   <SAFETY or FAS population >) ;
 ******************************************************************************/
%LOCAL macro mversion _starttime macro_parameter_error  ;
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

%put >>>>>>>>>&pop.<<<<<<<<<<<<<<<<<<<<;

/*%global  eva_param_extend_var eva_param_extend_rule;*/
/*%let eva_param_extend_var=;*/
/*%let eva_param_extend_rule=;*/

%load_ads_dat(&ads._view  , adsDomain = &ads. , adslWhere =  &pop. );
%load_ads_dat(adsl_view   , adsDomain = adsl  , where     =  &pop. );



%extend_data(indat = &ads._view , outdat =  &ads. );
%extend_data(indat = adsl_view  , outdat = adsl) ;


data &ads. ;
   set &ads.  ;

where paramcd = "&param1."
      and parcat1 = "&param2."
      and not missing(avisitn)
      and not missing(aval)
      and ANL04FL = "Y"
     ;

if ( 5 <= avisitn <= 260 ) or ( 700000 <= avisitn <= 700040 ) ;

attrib  TRT01PN  label = "Treatment"
         pchg    label = "Relative change (%)";
run;


* Produce dataset for TABLESBY ;
proc sort data=&ads.  out=tby (keep = &param. ) nodupkey;
    by &param.  ;
run;


%MTITLE;


%desc_tab(
        data           = &ads.
      , data_n       =  adsl
      , var          =   aval
      , stat         =  n mean std min median max
      , page         =  &param.
      , order        =  &param.
      , vlabel       = no
      , baseline     = ablfl = "Y"
      , compare_var  = pchg
      , time         =   Avisitn
      , visittext    = Visit
      , baselinetext = baseline at visit
      , subject      = subjid
      , tablesby     = Tby
      , optimal      = yes
      , total        = NO
      , round_factor = &round.
      , class        =   &treat_arm_p.
      , class_order  = &treat_arm_p. = &MOSTO_PARAM_CLASS_ORDER.
      , data_n_ignore = &param.
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

%MEND m_mean_base_chgp;
