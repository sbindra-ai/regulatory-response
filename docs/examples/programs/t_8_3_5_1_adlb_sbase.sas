/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY 3427080, no drug Elinzanetant related - OS
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_3_5_1_adlb_sbase );
/*
 * Purpose          : Laboratory data: summary statistics and change from baseline by visit -
 *                  {HEMATOLOGY, parameter name, unit} (SAF)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 11DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/t_8_3_5_1_adlb_sbase.sas (emvsx (Phani Tata) / date: 28JUL2023)
 ******************************************************************************/

%load_ads_dat(
    adlb_view
  , adsDomain = adlb
  , where = anl01fl = "Y"
          and      avisitn < 900000
          and not missing (paramcd)
          and not missing (aval)
          and parcat1   in ( "HEMATOLOGY" )
          and  avisitn ^= 500000

  , adslWhere = &saf_cond and n(TRT01AN)
  , adslVars  = SAFFL FASFL TRT01AN

)
%load_ads_dat(adsl_view , adsDomain = adsl , where =  &saf_cond );

%extend_data(indat = adlb_view , outdat = adlb )
%extend_data(indat = adsl_view  , outdat = adsl) ;

**get rounding factor from SLAT;
PROC SORT DATA=g_data.slat(KEEP=test roundf_c)
     OUT=rounding(RENAME=(test=paramcd)) NODUPKEY;
    BY test roundf_c;
RUN;

PROC SORT DATA=adlb ;
    BY paramcd;
run;

DATA adlb;
    MERGE adlb (IN=a) rounding;
    BY paramcd;
    IF a;

    %M_PropIt(Var=parcat1);*changing Parcat1 to sentence case*;
    parcat1 = parcat1_prop ;

     if missing(roundf_c) then roundf_c = 0.01 ;
      label  &treat_var. = "Treatment";
RUN;

**produce dataset for TABLESBY ;
PROC SORT DATA=adlb(KEEP=parcat1 paramcd paramn  )    OUT=tby nodupkey;
    BY   parcat1 paramcd;
RUN;

PROC SORT DATA=adlb ;
    BY   parcat1 paramcd;
RUN;
**set titles and footnotes, create output;
%MTITLE;
%desc_tab(
    data         = adlb
  , var          = aval
  , stat         = n mean std min median max
  , class        = avisitn
  , class_order  = avisitn
  , total        = NO
  , round_factor  = roundf_c
  , vlabel       = no
  , baseline     = ablfl = "Y"
  , compare_var  = chg
  , time         = &treat_var.
  , visittext    = visit
  , baselinetext = baseline at visit
  , subject       = &subj_var
  , optimal      = yes
  , bylen        = 30
  , tablesby      = tby
  , page          =  parcat1 paramcd paramn
  , data_n_ignore =  parcat1 paramcd paramn
  , order         =  parcat1 paramcd paramn
)




%endprog;


