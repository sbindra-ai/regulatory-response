/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_2_3_1_hfss_hf_s  );
/*
 * Purpose          : Proportion of subjects with at least a reduction of <<25%/50%/75%/2.6/5.8>> in mean daily
 *                    frequency of moderate to severe hot flashes by treatment group (FAS)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 29NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/t_8_2_3_1_hfss_hf_s.sas (emvsx (Phani Tata) / date: 28SEP2023)
 ******************************************************************************/

%macro crit ( crit =  );

%load_ads_dat(fss_view, adsDomain = adqshfss , adslWhere =  &fas_cond );
%load_ads_dat(adsl_view , adsDomain = adsl , where =  &fas_cond ) ;


%extend_data(indat = fss_view , outdat =  adqs );
%extend_data(indat = adsl_view  , outdat = adsl) ;

*HFDB998 - Mean daily frequency of moderate to severe hot flashes*;
data adqs ;
    set adqs ;
    where paramcd = "HFDB998" and   parcat1 = "TWICE DAILY HOT FLASH DIARY V2.0" and
          Avisitn In (40,120 , 260) and ANL04FL="Y"  ;
         attrib   crit1fl  label = " " ;
       crit = CRIT&crit. ;
       critfl = CRIT&crit.fl ;
       if critfl = "Y" then critfln = 1;
       else if critfl = "N" then critfln = 2;
       else  critfln = 3 ; ;
       format critfl   $X_NY. ;
       attrib  avisitn  label = "Time";
run;


proc sort data=adqs (keep = crit )       out=tby  nodupkey;
    by crit ;
run;


%MTITLE;

%freq_tab(
    data        = adqs
  , data_n      = adsl
  , var         = critfl
  , subject     = &subj_var.
  , by          =   crit  avisitn
  , order       =    critfl crit
  , total       = NO
  , class       = &treat_arm_p
  , hlabel      = Yes
  , tablesby    = tby
  , layout      = MINIMAL_BY
  , print_empty = NO
  , order_var =  critfl = "Y" "N" ""
  , misstext  = Missing
  , data_n_ignore       =   critfl
);

%mend ;

%crit ( crit = 1   );


/* Use %endprog at the end of each study program */
%endprog;
