/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name= l_10_2_2_addv_imp_pd_cvd);
/*
 * Purpose          : Listing of important protocol deviations associated with COVID-19 pandemic
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gniiq (Mayur Parchure) / date: 21OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/l_10_2_2_addv_imp_pd_cvd.sas (gniiq (Mayur Parchure) / date: 21OCT2023)
 ******************************************************************************/

%m_create_ads_view(
    adsDomain = addv
  , outDat    = addvall
  , adslVars  = COUNTRY SASR ETHNIC INVNAM EP1DVFL &TREAT_VAR
)

%extend_data(indat = addvall, outdat = addv)

DATA addv_final
     (KEEP=SUBJIDN USUBJID USARE COUNTRY Visit DVDECOD DVTERM &TREAT_VAR IDREQIMD INVNAM );
     SET addv;
     LENGTH usare $70.;
     subjidn=input(usubjid,best.);
     usare= CATX('/',SASR,ETHNIC);
     WHERE EP1DVFL= 'Y' AND ~missing(IDREQIMD);
     LABEL COUNTRY  = 'Country/Region'
           USARE    = 'Subject Identifier/# Age/ Sex/# Race/# Ethnicity'
           INVNAM   = "Investigator"
           DVDECOD  = 'Protocol Deviation Coded Term'
           IDREQIMD = 'Protocol Deviation Subcategory'
           DVTERM   = 'Protocol Deviation Term'
           Visit    = 'Visit'
           &TREAT_VAR = "Actual Treatment Group";
RUN;

PROC SORT DATA=addv_final ;
    BY COUNTRY subjidn usare  DVDECOD ;
RUN;


%MTITLE;

%datalist(
    data            = addv_final
  , page            = &TREAT_VAR
  , by              = COUNTRY
  , var             = INVNAM USARE Visit DVDECOD IDREQIMD DVTERM
  , order           = SUBJIDN
  , order_var       = &TREAT_VAR = 100 101 .
  , maxlen          = 18
  , hsplit          = "#"
  , bylen           = 40
  , ignore_prespace = yes
  , hb_align        = LEFT
  , hv_align        = LEFT
)


%endprog()