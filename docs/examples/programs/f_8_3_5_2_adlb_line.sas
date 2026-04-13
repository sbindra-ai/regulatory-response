/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = f_8_3_5_2_adlb_line  );
/*
 * Purpose          : Line plot  General Chemistry Parameter , name unit by treatment Group
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 29FEB2024
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/f_8_3_5_2_adlb_line.sas (emvsx (Phani Tata) / date: 06OCT2023)
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
          and parcat1   = "&par."  and
         paramcd in ('CKSP' 'LDH' 'ESTD3G'  'HBA1C' 'CHOLSP'
           'HDL' 'LDL' 'SGOTSP' 'SGPTSP' 'ALKPHOSP' 'BILITOSP' 'TRIGLY' 'PTINR' );

RUN;
DATA adlb;
    MERGE adlb (IN=a) rounding;
    BY paramcd;
    IF a;
  if avisitn ^= 500000 ;
     if missing(roundf_c) then roundf_c = 0.01 ;
     %M_PropIt(Var=parcat1);*changing Parcat1 to sentence case*;
     parcat1 = parcat1_prop ;
        ** round AVAL BASE and CHG **;
        aval2= chg ;
      label TRT01AN= "Actual Treatment" ;

RUN;
*As per Clinical team (Taru,Christian ) request 02/24/2024 to spread visits *;
data adlb ;
  set  adlb ;
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
**produce dataset for TABLESBY ;
PROC SORT DATA=adlb(KEEP=parcat1 paramcd paramn  ) OUT=tby nodupkey;
    BY   parcat1 paramcd;
RUN;


PROC SORT DATA=adlb ;
    BY   parcat1 paramcd;
RUN;


%MTITLE;


%gral_style(
   markers         = CircleFilled
  , graphdatadefault = linethickness=2px )

%MeanDeviationPlot(
    data     = adlb
  , xvar     = n_avsitn
  , yvar     = aval2
  , class    =  &treat_arm_a.
  , xtype    = data
  , filename = &prog.
  , ylabel   = Chg. in $paramcd$
  , by       = paramcd
  , title_ny    = No
  , legendtitle = Treatment Group
  , data_n        = adsl
   , data_n_ignore = paramcd
  , xlabel      = Time (weeks)
  , subject     = usubjid
  , style    = report2
  , stat     = ARITH_CL95          /* Figure describes the time course of mean and 95% confidence interval */
);
%mend;


%subgrp(cond=&saf_cond, arm=&treat_arm_a., label_=&saf_label. ,
par = %str(GENERAL CHEMISTRY) );

%endprog(
    cleanWork       = y
  , cleanTitlesFoot = y
  , verbose         = Y
)

;