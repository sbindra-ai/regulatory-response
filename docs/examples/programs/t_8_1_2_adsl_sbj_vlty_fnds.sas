/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_1_2_adsl_sbj_vlty_fnds);
/*
 * Purpose          : Analysis sets and validity findings (all enrolled subjects)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : enpjp (Prashant Patel) / date: 27DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_1_2_adsl_sbj_vlty_fnds.sas (enpjp (Prashant Patel) / date: 09SEP2023)
 ******************************************************************************/

%load_ads_dat(
    adsl_view
  , adsDomain = adsl
  , where     = &RAND_COND.
);

%extend_data(indat = adsl_view, outdat = adsl)

data final;
    set adsl_view;
    if slasfl = "N" and slaexre1 eq " " then slaexre1 ="Randomized subjects who have not signed the informed consent for sleep quality tracking sub-study";
RUN;

%mtitle();

%overview_tab(
    data     = final
  , data_n   = adsl_view(where=(&RAND_COND))
  , class    = &TREAT_ARM_P
  , misstext = Missing
  , subject  = subjid
  , total    = yes
  , groups   = "&fas_cond"                *'Subjects valid for FAS'
               "&saf_cond"                *'Subjects valid for SAF'
               "&slas_cond"               *'Subjects valid for SLAS'

               '<DEL>'                    *' '

               "not(&saf_cond) "          *'Excluded from SAF'
/*               "EXNYOVLN eq 0"            *'    Never took study drug'*/
               "saffl = 'N'"   *'<DEL>'   *'safexre1'*'<DEL>'
               '<DEL>'                    *' '

               "not(&fas_cond)"           *'Excluded from FAS'
               "fasfl = 'N'"   *'<DEL>'   *'fasexre1'*'<DEL>'
               '<DEL>'                    *' '

               "not(&slas_cond)"           *'Excluded from SLAS'
               "slasfl = 'N'"   *'<DEL>'   *'slaexre1'*'<DEL>'
               '<DEL>'                    *' '
  , maxlen   = 25
  , freeline =
  , bylen    = 80
)

/* Use %endprog at the end of each study program */
%endprog();


