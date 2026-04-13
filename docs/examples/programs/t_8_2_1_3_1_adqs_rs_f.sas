/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_2_1_3_1_adqs_rs_f   );
/*
 * Purpose          : PROMIS SD SF 8b raw item score:
 *                    Number of subjects by treatment group (FAS)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : emvsx (Phani Tata) / date: 29NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/t_8_2_1_3_1_adqs_rs_f.sas (emvsx (Phani Tata) / date: 27JUL2023)
 ******************************************************************************/

*To Run Macro for various Paramcd's *;
%macro paramcd (par= ,  formtn   =   );


%load_ads_dat(
    adqs_view
  , adsDomain = adqs
  , where     = parcat1 = "PROMIS SLEEP DISTURBANCE SHORT FORM 8B V1.0"
                and paramcd = "&par."
                and 5 <= avisitn <= 700000
                and anl04fl = "Y"
  , adslWhere = &fas_cond
)
%load_ads_dat(adsl_view , adsDomain = adsl , where =  &fas_cond )



%extend_data(indat = adqs_view , outdat =  adqs );
%extend_data(indat = adsl_view  , outdat = adsl) ;

data adqs  ;
    set adqs  ;

aval_n   = input( strip(put( avalc ,  $&formtn.  )) ,  3. ) ;
format aval_n  &formtn.;

*< Please chk the Paramcd Label to be consistent with Graph*;
          attrib  paramcd Label ="PROMIS SD 5-point scale"
                  avisitn Label ='Time';
run;

%MTITLE;

%freq_tab(
    data        = adqs
  , data_n      = adsl
  , var         = aval_n
  , subject     = &subj_var.
  , by          = avisitn
  , class       = TRT01PN
  , hlabel      = Yes
  , missing     = NO
  , layout      = MINIMAL_BY
  , print_empty = NO
  , total       = NO

  , page     = paramcd
  , data_n_ignore       =  paramcd
);

%mend ;

%paramcd (par = %str(PSDSB101) ,  formtn   = _prawsf. );
%paramcd (par = %str(PSDSB102) ,  formtn   = _prawsfs. );
%paramcd (par = %str(PSDSB103) ,  formtn   = _prawsfs. );
%paramcd (par = %str(PSDSB104) ,  formtn   = _prawsf. );

%paramcd (par = %str(PSDSB105) ,  formtn   = _prawss. );
%paramcd (par = %str(PSDSB106) ,  formtn   = _prawss.  );
%paramcd (par = %str(PSDSB107) ,  formtn   = _prawsse. );
%paramcd (par = %str(PSDSB108) ,  formtn   = _prawse. );
/**/
/* Use %endprog at the end of each study program */
%endprog;
