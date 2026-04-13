/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_3_2_1_adae_ovrlpsttrt, log2file = Y);
/*
 * Purpose          : Post-treatment adverse events: overall summary of number of subjects  (SAF)
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : enpjp (Prashant Patel) / date: 10SEP2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_3_2_1_adae_ovrlpsttrt.sas (enpjp (Prashant Patel) / date: 22AUG2023)
 ******************************************************************************/


*get data and select only Safety patients;
%load_ads_dat(adae_view, adsDomain = adae, where = postfl="Y" , adslWhere = &saf_cond.)/*PREFL ==> Post-Pretreatment Flag*/
%load_ads_dat(adsl_view, adsDomain = adsl, where = &saf_cond, adslVars  =);

%extend_data(indat = adsl_view, outdat = adsl)
%extend_data(indat = adae_view, outdat = adae)


%mtitle;
%overview_tab(
    data     = adae_view
  , data_n   = adsl_view
  , class    = trt01an
  , misstext = MISSING
  , total    = NO
  , groups   = '<DEL>'                                  *'Number (%) of subjects with post-treatment adverse events'
                'aeterm ne " "'                         *'Any AE'
                'aeterm ne " "'*'<DEL>'*'max(asevn)'    *'Maximum intensity for any AE'
                'areln = 1'                             *'Any study drug-related AE'
                'aerelpr = "Y"'                         *'Any AE related to procedures required by the protocol'
                'assiny = "Y"'                          *'Any AE of special interest'
                '<DEL>'                                 *'   '
                'aeser = "Y"'                           *'Any SAE'
                'aeser = "Y" and areln = 1'             *'Any study drug-related SAE'
                'aeser = "Y" and areln = 1'             *'Any SAE related to procedures required by the protocol'
                '<DEL>'                                 *'   '
                'aesdth = "Y"'                          *'AE with outcome death'
  , maxlen   = 20
  , hsplit   = #
  , freeline =
  , bylen    = 60
)

/* Use %endprog at the end of each study program */
%endprog;