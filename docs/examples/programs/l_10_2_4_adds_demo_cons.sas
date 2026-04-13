/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(
      name     = l_10_2_4_adds_demo_cons);
/*
 * Purpose          : Informed consent
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gniiq (Mayur Parchure) / date: 13OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/l_10_2_4_adds_demo_cons.sas (gniiq (Mayur Parchure) / date: 13OCT2023)
 ******************************************************************************/

%m_create_ads_view(
    adsDomain = adds
  , outDat    = addsall
)

%extend_data(indat = addsall, outdat = adds)

%m_create_dtl(inputds = adds, varname = DSSTDTL)

DATA adds1 ;
     SET adds
         (WHERE=( DSDECOD= 'INFORMED CONSENT OBTAINED' AND DSCAT= 'PROTOCOL MILESTONE' AND ~missing(AMENDNO)));

      AMENDNO1=strip(put(AMENDNO,best.));
      LABEL DSSTDTL                   = "Informed Consent Date";
      LABEL SASR                  = "Subject Identifier/ Age/ Sex/ Race";
      LABEL AMENDNO1                  = "Protocol Amendment Number";
      LABEL &treat_var_listings_part = "Planned Treatment Group";
RUN;

%MTITLE;

%datalist(
    data   = adds1
  , page   = &treat_var_listings_part.
  , by     = SASR
  , var    = AMENDNO1 DSSTDTL
  , order_var = &treat_var_listings_part.= 100 101
  , maxlen = 20
  , hsplit = "#"
  , bylen  = 25
  , optimal = N
)

%endprog()