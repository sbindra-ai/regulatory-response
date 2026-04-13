/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(
       name     = l_10_2_4_admh_demo);
/*
 * Purpose          : Medical history
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gniiq (Mayur Parchure) / date: 13OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/l_10_2_4_admh_demo.sas (gniiq (Mayur Parchure) / date: 13OCT2023)
 ******************************************************************************/

%m_create_ads_view(
    adsDomain = admh
  , outDat    = admhall
)

%extend_data(indat = admhall, outdat = admh)

%m_create_dtl(inputds=admh, varname= MHSTDTL);

%m_create_dtl(inputds=admh, varname= MHENDTL);

DATA admh_final;
    SET admh(WHERE=(SCRNFLFL='N'));

    SUB_ASR=SASR;
    MHTERM=strip(upcase(MHTERM));
    *** As defined in Programmer comments -> Add column "System Organ Class/ High Level Term/ Preferred Term" ***;

    LABEL SUB_ASR                  = "Subject Identifier/#Age/ Sex/ Race";
    LABEL MHTERM                   = "Medical History Finding";
    LABEL MHSTDTL                  = "Start Date";
    LABEL MHENRTPT                 = "Ongoing at {at informed#consent}/ {at start of#study intervention}"; /* as seen in CRF */
    LABEL MHENDTL                  = "End Date";
    LABEL &treat_var_listings_part = "Planned Treatment Group";
 RUN;

 %MTITLE;

 *** Display MHTERM as it is defined in study data. No need to UPPERCASE terms as in TLF suggested ***;
 %datalist(
      data     = admh_final
    , page     = &treat_var_listings_part.
    , by       = SUB_ASR MHTERM
    , var      = MHSTDTL MHENRTPT MHENDTL
    , freeline = SUB_ASR
    , together = SUB_ASR
    , optimal  = N
    , maxlen   = 40
    , bylen    = 25
    , hsplit   = "#"
 );

 %endprog()
