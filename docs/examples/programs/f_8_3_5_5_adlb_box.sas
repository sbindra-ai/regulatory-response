/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = f_8_3_5_5_adlb_box   );
/*
 * Purpose          : Box plot VITAMINS Parameter , name unit by treatment Group
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 27NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/f_8_3_5_5_adlb_box.sas (emvsx (Phani Tata) / date: 02OCT2023)
 ******************************************************************************/
%macro subgrp(cond=, arm=, label_= ,  par = ,  label_y =   );

%load_ads_dat(
    adlb_view
  , adsDomain = adlb
  , adslWhere = &cond. and n(&arm.)
  , adslVars  = SAFFL FASFL &arm.
)
%load_ads_dat(adsl_view , adsDomain = adsl , where =  &saf_cond );


%extend_data(indat = adlb_view , outdat = adlb )
%extend_data(indat = adsl_view  , outdat = adsl) ;

**get rounding factor from SLAT;
PROC SORT DATA=g_data.slat(KEEP=test roundf_c) OUT=rounding(RENAME=(test=paramcd)) NODUPKEY;
    BY test roundf_c;
RUN;
PROC SORT DATA=adlb ;
    BY paramcd;

    where anl01fl = "Y"
      and   0 < avisitn < 900000
          and not missing(paramcd)
          and not missing (aval)
          and parcat1   = "&par."  ;
RUN;
DATA adlb;
    MERGE adlb (IN=a) rounding;
    BY paramcd;
    IF a;
    %M_PropIt(Var=parcat1);*changing Parcat1 to sentence case*;
    parcat1 = parcat1_prop ;
     if missing(roundf_c) then roundf_c = 0.01 ;
        ** round AVAL BASE and CHG **;
        aval2= aval ;
      label TRT01AN= "Actual Treatment" ;
RUN;

**produce dataset for TABLESBY ;
PROC SORT DATA=adlb(KEEP=parcat1 paramcd paramn  ) OUT=tby nodupkey;
    BY   parcat1 paramcd;
RUN;


PROC SORT DATA=adlb ;
    BY   parcat1 paramcd;
RUN;


%MTITLE;

%BoxPlot(
    data          = adlb
  , xvar          = avisitn
  , yvar          = aval2
  , by            = paramcd
  , class         = &treat_arm_a.
  , class_order   = &mosto_param_class_order.
  , title_ny      = No
  , legend        = yes big_n
  , legendtitle   = Treatment Group
  , data_n        = adsl
  , data_n_ignore = paramcd
  , subject       = usubjid
  , desc_footnote    = NO
  , connect       = mean
  , extremes      = NO
  , xlabel        = Time (weeks)
  , ylabel        = $paramcd$
  , filename      = &prog.
)


%mend;

%subgrp(cond=&saf_cond, arm=&treat_arm_a., label_=&saf_label. ,
       par = %str(VITAMINS) );

%endprog(
    cleanWork       = y
  , cleanTitlesFoot = y
  , verbose         = Y
)

;


