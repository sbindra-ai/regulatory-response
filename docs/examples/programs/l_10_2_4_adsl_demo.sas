/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name     = l_10_2_4_adsl_demo);
/*
 * Purpose          : Creation of Demographics table
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gniiq (Mayur Parchure) / date: 13OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/l_10_2_4_adsl_demo.sas (gniiq (Mayur Parchure) / date: 13OCT2023)
 ******************************************************************************/

%create_ads_view(
    adsDomain = adsl
  , outDat    = adsl_view
)

%extend_data(indat = adsl_view, outdat = adsl)

DATA adsl1;
    SET adsl
        (WHERE=(SCRNFLFL='N') KEEP=USUBJID UASR &treat_var_listings_part. EDULEVEL BRTHDTC RACE: HEIGHTBL WEIGHTBL BMIBL SCRNFLFL);
    LENGTH Racem $200.;
    IF sum(~missing(Race1),~missing(Race2),~missing(Race3),~missing(Race4),~missing(Race5)) > 1 THEN
    Racem=catx(', ',Race1,Race2,Race3,Race4,Race5);
    ELSE Racem='';
    SUBJID=substr(USUBJID,6);
    SUBJIDN=input(SUBJID,best.);
    ASR= substr(UASR,16);
    HEIGHTBL_=put(HEIGHTBL,8.);
    WEIGHTBL_=put(WEIGHTBL,8.2);
    BMIBL_=put(BMIBL,8.1);

    LABEL &treat_var_listings_part. ="Treatment Group";
    LABEL RACEM = "Multiple Races";
    LABEL ASR = "Age/ Sex/#Race";
    LABEL HEIGHTBL_ = "Baseline#Height#(cm)";
    LABEL WEIGHTBL_ = "Baseline#Weight#(kg)";
    LABEL BMIBL_ = "Baseline Body#Mass Index#(kg/m2)";
    LABEL BRTHDTC = "Birth#Year";
    LABEL SUBJID = "Subject#Identifier";
    LABEL EDULEVEL = "Level of education";
    LABEL &treat_var_listings_part. = "Planned Treatment Group";
RUN;


%MTITLE;

%datalist(
    data            = adsl1
  , page    = &treat_var_listings_part.
  , by              = SUBJIDN SUBJID
  , var             = BRTHDTC ASR EDULEVEL RACEM  HEIGHTBL_ WEIGHTBL_ BMIBL_
  , order           = SUBJIDN
  , maxlen          = 25
  , hsplit          = "#"
  , bylen           = 10
  , ignore_prespace = yes
)

%endprog()