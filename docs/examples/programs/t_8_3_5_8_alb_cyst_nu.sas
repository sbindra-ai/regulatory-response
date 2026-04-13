/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name =  t_8_3_5_8_alb_cyst_nu  );
/*
 * Purpose          :Table: Number of subjects fulfilling the liver injury criteria  (SAF)
 * Programming Spec :
 * Validation Level :2 - Verification by Double Programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 07DEC2023
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : emvsx (Phani Tata) / date: 21FEB2024
 * Reason           : Updated table as per req
 ******************************************************************************/

*Load datasets;
%load_ads_dat(
    adqs_view
  , adsDomain = adqs
  , adslWhere =   n(&treat_arm_a.)
  , adslVars  = SAFFL FASFL &treat_arm_a.   trtedt   trtsdt &treat_arm_a.
  , where  = Parcat1 = "CLOSE LIVER OBSERVATION CASE REVIEW (V1.0)"
             and paramcd = "CLB105"
)

%load_ads_dat(adsl_view , adsDomain = adsl , where =  &saf_cond );

%extend_data(indat = adqs_view , outdat = adqs  )
%extend_data(indat = adsl_view  , outdat = adsl) ;

proc sort data = sp.ce out = ce (keep = usubjid cedtc  ) ;
    by usubjid cedtc;
run;
data ce_l ;
    set ce;
    by usubjid cedtc;
    if last.usubjid ;
    cedtn = input(cedtc, yymmdd10.);
    format cedtn date9. ;
RUN;

proc sort data = ce_l  ;
    by   usubjid ;
run;
proc sort data = adqs  ;
    by   usubjid ;
run;

data adqs ;
    merge adqs ( in = a ) ce_l ( in = b );
    by   usubjid ;
    if b ;

RUN;

data adqs22 ;
  set adqs  ;
  if Avalc = "No" then critfln = 3 ;
run;
data adqs ;
   set adqs  ;

   if Avalc = "No" then critfln = 1;
   else if Avalc  = "Yes" then critfln = 2;
   else  critfln = 3 ; ;

   Format critfln _ynm.;
   Label  paramcd = ' ';

run;

proc sort data=adqs (keep = paramcd )       out=tby  nodupkey;
    by paramcd ;
run;

%freq_tab(
    data        = adqs22
  , data_n      = adsl
  , var         = critfln
  , subject     = &subj_var.
  , by          = paramcd
  , total       = NO
  , class       =  &treat_arm_a.
  , hlabel      = Yes
  , label       = No
  , basepct     = N_CLASS
  , misstext    = Missing
  , data_n_ignore  = paramcd
  , print_empty    = YES
  , missing        = NO
  , complete       = NONE
  , completeclass  = DATA
  , outdat         = _stat0

);

%freq_tab(
    data        = adqs
  , data_n      = adsl
  , var         = critfln
  , subject     = &subj_var.
  , by          = paramcd
  , total       = NO
  , class       =  &treat_arm_a.
  , hlabel      = Yes
  , label       = No
  , order_var   =  critfln = "No" "Yes" "Missing"
  , misstext    = Missing
  , data_n_ignore  =     paramcd
  , print_empty = Yes
  , missing  = Yes
  , complete = ALL
  , completeclass       = DATA
  , outdat =  _stat1
);

data _stat0__1 (rename = (_cptog1_n1 = _cptog1   _cptog1_n2 = _cptog2 ) );
    length _cptog1_n1 _cptog1_n2 $200. ;
    set _stat0;

    _cptog1_n1  = cat( substr(_cptog1  , 1 , 10 ) , cat (' (' ,strip(substr(_cptog1  , 11 , 6 )) , ')'  )  ) ;
    _cptog1_n2  = cat( substr(_cptog2  , 1 , 1 ) , cat (' (' ,strip(substr(_cptog2  , 2 , 6 )), ')'  ) ) ;

 drop _cptog1    _cptog2          ;
RUN;

data _stat0;
    length Paramcd_n $100;
    set _stat0__1 ;
    Paramcd_n = "Case Met Close Liver Observation";
    _ord_ = 0; _newvar = 0 ;_nr2_ = 1;
    _varl_ = 'n' ;
RUN;

data _stat1 ;
    length Paramcd_n $100;
    set _stat1 ;
    if _varl_ = 'n' then delete  ;
    Paramcd_n = "Case Met Liver Injury Criteria";
RUN;

data _stat1 ;
    set _stat0 _stat1 ;
run;

%mtitle ;

DATA _statinp;
    SET _stat1inp;
    IF keyword = "BY" THEN value = "Paramcd_n _widownr _nr2_ _ord_ _newvar _type_ _kind_ _varl_";
    IF keyword = "ORDER" THEN value = "  _widownr _nr2_ _ord_ _newvar _type_ _kind_";
    IF keyword = 'FREELINE' THEN value = 'Paramcd_n';
    IF keyword = 'TOGETHER' THEN value = 'Paramcd_n';
RUN;

%mosto_param_from_dat(
    data    = _statinp
  , var     = Paramcd_n
  , keyword = keyword
  , value   = value
)


%datalist(&Paramcd_n);

/* Use %endprog at the end of each study program */
%endprog;
