/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name     = l_10_2_2_adsl_trt_grp);
/*
 * Purpose          : Subjects whose actual treatment group was not the planned (randomized) treatment
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gniiq (Mayur Parchure) / date: 13OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/l_10_2_2_adsl_trt_grp.sas (gniiq (Mayur Parchure) / date: 13OCT2023)
 ******************************************************************************/


%create_ads_view(
    adsDomain = adsl
  , outDat    = adsl_view
)

%extend_data(indat = adsl_view, outdat = adsl)

DATA adsl_01;
    SET adsl(WHERE=(RANDFL='Y'));
    LENGTH SUB_ASR $40;
    SUB_ASR=SASR;
    IF &treat_var. NE &treat_var_listings_part;
    LABEL SUB_ASR = "Subject Identifier/ Age/ Sex/ Race";
    LABEL TRT01AN='Actual Treatment Group';
    LABEL TRT01PN='Planned Treatment Group';
RUN;

%MTITLE;

%datalist(
    data            = adsl_01
  , by              = SUB_ASR
  , var             = TRT01PN TRT01AN
  , freeline        =
  , together        =
  , optimal         = YES
  , maxlen          = 25
  , hsplit          = "#"
  , bylen           = 20
  , ignore_prespace = NO
)


%endprog()
