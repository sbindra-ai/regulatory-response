%MACRO m_mean_chg_subgrp(param =, ads   =    ,  subgrp = ,  pop =  , pop_label1= )
/ DES = 'Summary statistics and change from baseline by treatment group';
/*******************************************************************************
 * Bayer AG
 * Macro rely on: pure SAS
 *******************************************************************************
 * Purpose          : Summary statistics and change from baseline by treatment group and subgroup
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
 * Author(s)        : eokcw (Vijesh Shrivastava) / date: 23SEP2023
 * Reference prog   :
 *******************************************************************************
 * Change History   :
 ******************************************************************************/

/*******************************************************************************
 * Examples         :
   %m_mean_chg_subgrp(param = paramcd ,
    ads   = adqshfss ,
    subgroup =  race,
    pop =   <SAFETY or FAS population >);

 ******************************************************************************/

%load_ads_dat(&ads._view  , adsDomain = &ads. , adslWhere =  &pop. );
%load_ads_dat(adsl_view   , adsDomain = adsl  , where     =  &pop. );

%extend_data(indat = &ads._view , outdat =  &ads. );
%extend_data(indat = adsl_view  , outdat = adsl) ;

data adsl;
    set adsl;
    attrib  RACE label ="Race";
    attrib  ETHNIC label ="Ethnicity";
    attrib region1n label="Region";
    format smokhxn _smk.;
    %M_PropIt(Var=race);
    %M_PropIt(Var=ethnic);
    race = RACE_PROP ;
    ethnic = ethnic_prop ;
RUN;


data &ads. ;
   set &ads.  ;
where paramcd = "&param."  and ANL04FL = "Y";
/*      and not missing(avisitn)*/
/*      and not missing(aval) ;*/
if ( 5 <= avisitn <= 260 ) or ( 700000 <= avisitn <= 700040 );
attrib  TRT01PN  label = "Treatment" ;

attrib  RACE label ="Race";
attrib  ETHNIC label ="Ethnicity";
attrib region1n label="Region";
format smokhxn _smk.;
%M_PropIt(Var=race);
%M_PropIt(Var=ethnic);
race = RACE_PROP ;
ethnic = ethnic_prop ;

run;


%mtitle();

%desc_tab(
    data         = &ads.
  , data_n       = adsl
  , var          = aval
  , stat         = n mean std min median max
  , page         = &subgrp.
  , class        = &treat_arm_p.
  , class_order  = &treat_arm_p. = &MOSTO_PARAM_CLASS_ORDER.
  , total        = NO
  , round_factor = 0.1
  , vlabel       = no
  , baseline     = ablfl = "Y"
  , compare_var  = chg
  , time         = Avisitn
  , baselinetext = baseline at visit
  , subject      = subjid
  , optimal      = yes
);


%endprog;

%MEND m_mean_chg_subgrp;
