/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name  = f_10_2_8_2_adlb_inr   );
/*
 * Purpose          : Figure: INR over time in subject <USUBJID> of <<treatment group>> (SAF)
 * Programming Spec :
 * Validation Level : 2 - Double programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 21FEB2024
 * Reference prog   : /var/swan/root/bhc/3427080/21810/stat/main01/val/analysis/pgms/f_10_2_8_2_adlb_inr.sas (emvsx (Phani Tata) / date: 21FEB2024)
 ******************************************************************************/

%macro over (par = , yref   = , yrefl  =  , ylabel =   , out = ) ;
 %load_ads_dat(
     adlb_view
   , adsDomain = adlb
   , where =
   , adslWhere =   n(&treat_arm_a.)
   , adslVars  = SAFFL FASFL &treat_arm_a.   trtedt   trtsdt
 )

%load_ads_dat(adsl_view , adsDomain = adsl , where =  &saf_cond );

%extend_data(indat = adlb_view , outdat = adlb )
%extend_data(indat = adsl_view  , outdat = adsl) ;

proc sort data = sp.ce out = ce (keep = usubjid cedtc ) ;
    by usubjid cedtc;
run;

data ce_l ;
    set ce;
    by usubjid cedtc;
    if last.usubjid ;
    cedtn = input(cedtc, yymmdd10.);
    format cedtn date9. ;
RUN;

proc sort data = adlb_view out = adlb ;
    by studyid usubjid ;
run;

proc sort data = adlb       out=adlb2;
     by usubjid   &treat_arm_a.  avisitn   ;
    where  paramcd in ( &par.  )  ;
 RUN;

data adlb2 ;
     merge adlb2 (in = a ) ce_l (in = b );
     by usubjid ;
     if b ; * Only CLO subjects are presented.*;
 RUN;
 data adlb2;
     set adlb2  ;
     if nmiss(trtsdt,trtedt)=0 then end_day = trtedt - trtsdt + 1;
    *Days since reference start date*;
   if nmiss(trtsdt,trtedt)=0 then lbdy = adt - trtsdt + 1;
 run;
 *******************************************************************************;
 *< Select lab parameters and normalize;
 *******************************************************************************;
 proc sort data=adlb2;
     by usubjid paramcd;
 run;
 *******************************************************************************;
 *< Select lab parameters and normalize;
 *******************************************************************************;
 proc sort data=adlb2;
     by usubjid paramcd;
 run;
 * Normalize values by ULN;
 data adlb3;
     set adlb2;
    * if 0 < anrhi then aval_norm = aval / anrhi ;
     aval_norm = aval ;
 run;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%mtitle
%LinePlot(
    data         = adlb3
  , xvar         = lbdy
  , yvar         = aval_norm
  , by           = usubjid   &treat_arm_a.
  , class        = paramcd
  , class_data   = adlb3
  , title_ny     = NO
  , legendtitle  = "Parameter"
  , style        = presentation
  , xrefline     = 1 end_day
  , xreflinetext = "First Dose"#"Last Dose"
  , xlabel       = "Days since reference start date"
  , yrefline     = &yref.
  , yreflinetext = &yrefl.
  , ylabel       = &ylabel.
  , subject      = usubjid
  , filename     = &prog._&out.
  , xshift       = NO
);

%mend ;


%over (par = %str( 'PTINR' ),
       yref = %str(1.5 2),
       yrefl  =  %nrstr('1.5' # '2' ) ,
       ylabel = %nrstr ("INR") ,
       out = %str(p2)
       ) ;

%endprog(
    cleanWork       = y
  , cleanTitlesFoot = y
  , verbose         = Y
)












