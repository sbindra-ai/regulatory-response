/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name     = l_10_2_4_adrp_demo);
/*
 * Purpose          : Reproductive and menstrual history
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gniiq (Mayur Parchure) / date: 13OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/l_10_2_4_adrp_demo.sas (gniiq (Mayur Parchure) / date: 13OCT2023)
 ******************************************************************************/

%create_ads_view(
    adsDomain = adrp
  , outDat    = adrp_view
)

%extend_data(indat = adrp_view, outdat = adrp)

DATA adrp_final;
    SET adrp;
    LABEL SASR   = "Subject Identifier/ Age/ Sex/ Race";
    LABEL PARAMCD= "Reproductive And Menstrual Findings";
    LABEL AVALC= "Result";
    LABEL &treat_var_listings_part = "Planned Treatment Group";
RUN;

%MTITLE;

%datalist(
     data     = adrp_final
   , page     = &treat_var_listings_part.
   , by       = SASR PARAMCD
   , var      = AVALC
   , freeline = SASR
   , together = SASR
   , hsplit   = "#"
   , maxlen   =35
   , bylen    = 45
   , optimal = NO)

%endprog()

