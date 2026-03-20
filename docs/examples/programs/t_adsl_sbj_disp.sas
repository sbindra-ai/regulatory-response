/*******************************************************************************
 * Bayer AG
 * Study            : 21652 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(
       name      = t_adsl_sbj_disp
     , createRTF =
   );
/*
 * Purpose          : Screen failures and reason in {study} (all enrolled subjects)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : eaiko (Venu Kunithala) / date: 22AUG2024
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_1_3_adds_sbj_disp.sas (enpjp (Prashant Patel) / date: 20DEC2023)
 ******************************************************************************/

%load_ads_dat(adsl_view, adsDomain = adsl, where = &enr_cond.)

data ie;
    set sp.ie;
    /*where IETESTCD in( "IN010",'EX013','EX014');*/
    keep USUBJID STUDYID IETESTCD IETEST IECAT IESCAT;
    proc sort;
        by studyid usubjid ;
RUN;

data adslie/*(where=(TRT01AN=))*/;
    merge adsl_view(in=in_adsl) ie (in=in_ie);
    by studyid usubjid;
    if in_adsl;
    /*if missing(IETESTCD) then reason="Any other inclusion/exclusion criteria"; else reason=strip(IETEST);*/
    if ^missing(IETESTCD) and IETESTCD in('EX014') then  reason=22;else
    if ^missing(IETESTCD) and IETESTCD in('EX013') then  reason=23;else
    if ^missing(IETESTCD) and IETESTCD in('IN010') then  reason=24;else
     if ^missing(IETESTCD) and IETESTCD Not in( "IN010",'EX013','EX014') then reason=25 ;else
      if missing(IETESTCD) then reason=26 ;
     format reason  if4fmt.;

run;
proc sort data=adslie; by usubjid reason; run;
proc sort data=adslie out=adslie_u nodupkey; by usubjid ; run;

title1 "Table: Screen failures and reason in {study}";
footnote1 "Number of subjects enrolled is the number of subjects who signed informed consent. ";
footnote2 "&idfoot";
/*< Enrolled and screening part */
%overview_tab(
    data                = adslie_u
  , class               = /* empty, only total needed */
  , missing             = NO
  , groups              = "&enr_cond."           *'Enrolled'     /* Number of subjects enrolled is the number of subjects who signed informed consent */
                      /*'SCRNFLFL = "Y"'*'Screening failures'*'reason'*'Primary reason'
                      '<DEL>'                         *''*/
  , groupstxt           = Number of subjects
  , n_group             = 1
  , complete            = none
  , percentage_decimals =
  , outdat              = out_table1
  , maxlen              = 30
  , hv_align            = LEFT
  , freeline            =
)
ods escapechar="^";
/*< Screen failure and reasons */
%overview_tab(
    data      = adslie_u
  , class     = /* empty, only total needed */
  , groups    = 'SCRNFLFL = "Y"' *'Screening failures'*'reason'*'Primary reason'
                      '<DEL>'                         *''
  , groupstxt = Number of subjects
  , n_group   = 1
  , complete  = none
  , outdat    = out_table2
  , maxlen    = 30
  , hv_align  = LEFT
  , freeline  =
)
ods escapechar="^";
data out_table2;
    set out_table2;
 if _order_ =2 then delete;
 y=input(translate(scan(put(_order_,best.),1,'.'),'2','1')||'.'||scan(put(_order_,best.),2,'.'),best.);
  if fline=1 then fline=2;
  drop  _order_;
  rename y=_Order_;
RUN;
data out_table1;
    set out_table1;
    _col3_=scan(_col1_,1,'(');
RUN;
/*< Combine tables and fix the trailing space for the first row */
data out_table;
    set out_table1(in=a drop=_col2_ _col1_) out_table2(in=b  drop=_col2_ rename=(_col1_=_col3_));
    if _order_=1 then _name_=strip(_name_);     /* Remove trailing space for Enrolled and Randomized category */
    if fline=2 then _name_="  " || _name_;
   RUN;

/*< Using inptable from randomized part */
data out_tableinp;
    set out_table2inp;
    if keyword="DATA" then value=tranwrd(value, "out_table2", "out_table");
    if keyword="VAR" then value=tranwrd(value, "_COL2_", "_COL3_");
    if keyword="FREELINE" then value=" FLINE";
RUN;

* print table without showing . for missing values;

%let _miss = %sysfunc(getoption(missing));
option missing=' ';

%mosto_param_from_dat(
    data = out_tableinp
  , var  = parameters
);
%datalist(&parameters);
%put &parameters;

option missing="&_miss.";

/* Use %endprog at the end of each study program */
%endprog;
