/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_3_2_3_adae_teae_ovrl, log2file = Y);
/*
 * Purpose          : Treatment-emergent adverse events: overall summary of number of subjects  (SAF)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : enpjp (Prashant Patel) / date: 05MAR2024
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_3_2_3_adae_teae_ovrl.sas (enpjp (Prashant Patel) / date: 09SEP2023)
 ******************************************************************************/


*get data and select only Safety patients;
%load_ads_dat(adae_view, adsDomain = adae, where = trtemfl="Y" AND NOT MISSING(aeterm), adslWhere = &saf_cond.)
%load_ads_dat(adsl_view, adsDomain = adsl, where = &saf_cond, adslVars  =);

%extend_data(indat = adsl_view, outdat = adsl)
%extend_data(indat = adae_view, outdat = adae)
/*Calculate Big "N" for each Phase column*/
%m_adae_bign;

data final;
    set adae_view1;
    aeacn_raw= upcase(substr(aeacn,1,1)) || lowcase(substr(aeacn,2));
    if aeacn_raw = "Dose not changed" then aecn=1;
    if aeacn_raw = "Drug interrupted" then aecn=2;
    if aeacn_raw = "Drug withdrawn" then aecn=3;
    if aeacn_raw = "Not applicable" then aecn=4;
    format aecn _acn. ;
RUN;

%mtitle;
%overview_tab(
    data     = final
  , data_n   = adsl_view1
  , class    = aphasen/*Phase variable*/
  , missing  = Yes
  , misstext = Missing
  , total    = no
  , groups   = '<DEL>'                                  *'Number (%) of subjects with treatment-emergent adverse events'
               '<DEL>'                                  *'   '
                'aeterm ne " "'                         *'Any AE'
                'aeterm ne " "'*'<DEL>'*'max(asevn)'    *'Maximum intensity for any AE'
                'areln = 1'                             *'Any study drug-related AE'
                'areln = 1'*'<DEL>'*'max(asevn)'        *'Maximum intensity for study drug-related AE'
                'aerelpr = "Y"'                         *'Any AE related to procedures required by the protocol'
                'aeacn =  "DRUG WITHDRAWN"'             *'Any AE leading to discontinuation of study drug'
                'assiny = "Y"'                          *'Any AE of special safety interest'
                '<DEL>'                                 *'   '

                'aeser = "Y"'                           *'Any SAE'
                'aeser = "Y" and aeterm ne " "'*'<DEL>'*'max(asevn)'    *'Maximum intensity for SAE'

                'aeser = "Y" and areln = 1'             *'Any study drug-related SAE'
                'aeser = "Y" and areln = 1 and aeterm ne " "'*'<DEL>'*'max(asevn)'    *'Maximum intensity for study drug-related SAE'

                'aeser = "Y" and aerelpr = "Y"'             *'Any SAE related to procedures required by the protocol'
                'aeser = "Y" and aeacn =  "DRUG WITHDRAWN"' *'Any SAE leading to discontinuation of study drug'
                'aeser = "Y" and aeterm ne " "'*'Action taken with SAE'*'aecn'*'Category'
                '<DEL>'                                 *'   '
                'aesdth = "Y"'                          *'AE with outcome death'
  , complete = ALL
  , maxlen   = 20
  , hsplit   = #
  , freeline =
  , bylen    = 40
)

/* Use %endprog at the end of each study program */
%endprog;