/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_3_7_adfapar_cyst_frq);
/*
 * Purpose          : Number of subjects with cyst like structures in ovary by visit and by treatment group  (SAF)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : epjgw (Roland Meizis) / date: 04DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/t_8_3_7_adfapar_cyst_frq.sas (egavb (Reema S Pawar) / date: 17JUN2023)
 ******************************************************************************/

%load_ads_dat(
    adfapr_view
  , adsDomain = adfapr
  , where     = anl01fl = "Y" and  PARCAT1 EQ 'ULTRASOUND' and paramcd = "CYSLSVIS"
  , adslWhere = &saf_cond
)
%load_ads_dat(adsl_view , adsDomain = adsl , where =  &saf_cond )

%extend_data(indat = adsl_view, outdat = adsl)
%extend_data(indat = adfapr_view, outdat = adfapr)


proc sort data = adfapr out =adfapr_sort ;
        by &subj_var. &treat_var  avisitn adt  PARAMCD FALAT AVALC;
run;

proc transpose data=adfapr_sort out = adfapr_trans (drop=  _NAME_ _LABEL_);
    by &subj_var. &treat_var  avisitn adt PARAMCD;
    var AVALC;
    id FALAT;
    idlabel FALAT;
run;

data final;
    set adfapr_trans;
    format anyovary $x_ny.;
    if LEFT = 'Y' or RIGHT = 'Y' then anyovary = 'Y' ; else anyovary = 'N';
    label anyovary = 'Cyst like structure visualized in any ovary';
RUN;

%MTITLE;


%freq_tab(
    data        = final
  , data_n      = adsl
  , var         = anyovary
  , subject     = &subj_var.
  , by          = avisitn
  , total       = NO
  , totaltxt    =
  , class       = &treat_var
  , header_bign = NO
  , misstext    =
  , missing     = NO
  , complete    = ALL
);

%endprog;