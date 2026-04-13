/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = f_8_3_5_3_adlb_box   );
/*
 * Purpose          : Box plot  COAGULATION Parameter , name unit by treatment Group
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 27NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/f_8_3_5_3_adlb_box.sas (emvsx (Phani Tata) / date: 07NOV2023)
 ******************************************************************************/


%macro subgrp(   paramcd = , range =  , par =   );
%load_ads_dat(
    adlb_view  , adsDomain = adlb
  , adslWhere = &saf_cond  and n(&treat_arm_a.)
  , adslVars  = SAFFL FASFL &treat_arm_a.
)
%load_ads_dat(adsl_view , adsDomain = adsl , where =  &saf_cond );
%extend_data(indat = adlb_view , outdat = adlb )
%extend_data(indat = adsl_view  , outdat = adsl) ;
options notes source ;

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
          and parcat1   = "COAGULATION"
          and avisitn ^= 500000  ;
RUN;
DATA adlb;
    MERGE adlb (IN=a) rounding;
    BY paramcd;
    IF a;
    if  &paramcd.   ;

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

  , connect       = mean
  , extremes      = NO
  , xlabel        = Time (weeks)
  , ylabel        = $paramcd$
  , filename      = &prog._&par.
  , yaxisbreakranges = &range.
  , axisbreaktype    = full
  , desc_footnote    = NO
)  ;


%mend;


%subgrp(paramcd = %nrstr(paramcd in ('APTT') ) ,  range = %str()  , par = cog1 );
%subgrp(paramcd = %nrstr(paramcd in ('PT') ) ,  range = %str(0-41 70-80)  , par = cog2 );
%subgrp(paramcd = %nrstr(paramcd in ('PTINR') ) ,  range = %str(0-2.5 4.5-5.0)  , par = cog3 );


%endprog(
    cleanWork       = y
  , cleanTitlesFoot = y
  , verbose         = Y
)

;