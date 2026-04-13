/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(
       name     = l_10_2_2_addv_pd);
/*
 * Purpose          : Protocol deviations
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gniiq (Mayur Parchure) / date: 18OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/l_10_2_2_addv_pd.sas (gniiq (Mayur Parchure) / date: 18OCT2023)
 ******************************************************************************/

%create_ads_view(
    adsDomain = addv
  , outDat    = addv_view
)

%extend_data(indat = addv_view, outdat = addv)

DATA addv_final;
    LENGTH dvterm2 $300;
    SET addv;
    *** Consider only important protocol deviations ***;
    IF DVCAT= "FINDING" AND ~missing(IDREQIMD);

    IF find(dvterm,'SOURCE:') > 0 THEN dvterm2= strip(scan(dvterm,-1,':'));
    ELSE dvterm2 = strip(dvterm);

    sub_asr =sasr;

    subjidn=input(USUBJID,best.);
    LABEL DVDECOD = "Protocol Deviation#Coded Term";
    LABEL DVTERM2  = "Protocol Deviation Term";
    LABEL Epoch     = "Epoch";
    LABEL SUB_ASR  = "Subject Identifier/#Age/ Sex/ Race";
    LABEL &TREAT_VAR = "Actual Treatment Group";
RUN;

*<*****************************************************************************;
*< Listing: Protocol deviations                                                ;
*<*****************************************************************************;

PROC SORT DATA=addv_final ;
    BY subjidn sub_asr  ;
RUN;

%MTITLE;

%datalist(
    data            = addv_final
  , page            = &TREAT_VAR
  , by              = SUB_ASR
  , var             =  DVDECOD DVTERM2
  , order_var = &TREAT_VAR = 100 101 .
  , maxlen          = 30
  , hsplit          = "#"
  , bylen           = 15
  , ignore_prespace = yes
)

%endprog()