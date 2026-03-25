/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adrp_iss_rpmens_hist);
/*
 * Purpose          : Custom table: Reproductive and menstrual history <<subgroup>> (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : erjli (Yosia Hadisusanto) / date: 14JUN2023
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : gdcpl (Derek Li) / date: 21JUN2023
 * Reason           : adapt to meet IA analysis requirement
 ******************************************************************************/
/* Changed by       : erjli (Yosia Hadisusanto) / date: 23JUN2023
 * Reason           : Update codes
 ******************************************************************************/
/* Changed by       : gdcpl (Derek Li) / date: 13SEP2023
 * Reason           : change the star(s) to (a)/(b) in footnote
 ******************************************************************************/
/* Changed by       : erjli (Yosia Hadisusanto) / date: 05DEC2023
 * Reason           : Update labels
 ******************************************************************************/
/* Changed by       : erjli (Yosia Hadisusanto) / date: 11DEC2023
 * Reason           : Add IF missing(hys) THEN hys = 0;
                          IF missing(os)  THEN os  = 0;
 ******************************************************************************/
/* Changed by       : erjli (Yosia Hadisusanto) / date: 27MAR2024
 * Reason           : Update label for births and pregnancies
 ******************************************************************************/

%LET mosto_param_class = %scan(&extend_var_disp_12_52_a., 1, '@');

%load_ads_dat(adsl_view, adsDomain = adsl);
%load_ads_dat(adrp_view, adsDomain = adrp)
%load_ads_dat(admh_view, adsDomain = admh);

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_12_52_a.
  , extend_rule = &extend_rule_disp_12_52_a.
);

%extend_data(
    indat       = adrp_view
  , outdat      = adrp_ext
  , var         = &extend_var_disp_12_52_a.
  , extend_rule = &extend_rule_disp_12_52_a.
);

%extend_data(
    indat       = admh_view
  , outdat      = admh_ext
  , var         = &extend_var_disp_12_52_a.
  , extend_rule = &extend_rule_disp_12_52_a.
);

** Steps to transpose ADRP parameters;
DATA adrp_ext;
    SET adrp_ext;
    ATTRIB param LENGTH = $200;
    param = vvalue(paramcd);
RUN;
PROC SORT DATA=adrp_ext; BY &subj_var.; RUN;

PROC TRANSPOSE DATA = adrp_ext OUT = adrp_ext_trans;
    BY &subj_var.;
    VAR aval;
    ID paramcd;
    IDLABEL param;
    format paramcd;
RUN;

DATA adrp_ext_trans;
    SET adrp_ext_trans;

    FORMAT brthn pregnn amenlen 8.1;

    ATTRIB amenlen          LABEL = "Duration of being amenorrheic (years)";
    ATTRIB brthc  brthn     LABEL = "Number of births";
    ATTRIB pregnc pregnn    LABEL = "Number of pregnancies";
    brthc  = brthn;
    pregnc = pregnn;
RUN;

** Derive Hysterectomy;
DATA hysterectomy(KEEP=&subj_var. hys);
    SET admh_ext(WHERE= (mhdecod IN ('Hysterectomy' 'Hysterosalpingectomy' 'Hysterosalpingo-oophorectomy' 'Radical hysterectomy')));
    ATTRIB hys LABEL = "Hysterectomy (a)" FORMAT = ny.;
    hys = 1;
RUN;
PROC SORT DATA=hysterectomy NODUPKEY; BY &subj_var.; RUN;

** Derive Oophorectomy;
DATA oophorectomy(KEEP=&subj_var. os);
    SET admh_ext(WHERE= (mhdecod IN ('Hysterosalpingo-oophorectomy' 'Oophorectomy' 'Oophorectomy bilateral' 'Salpingo-oophorectomy' 'Salpingo-oophorectomy bilateral' 'Salpingo-oophorectomy unilateral')));
    ATTRIB os LABEL = "Oophorectomy (b)" FORMAT = ny.;
    os = 1;
RUN;
PROC SORT DATA=oophorectomy NODUPKEY; BY &subj_var.; RUN;

%mergeDat(baseDat = adrp_ext_trans, keyDat = hysterectomy, by = &subj_var.)
%mergeDat(baseDat = adrp_ext_trans, keyDat = oophorectomy, by = &subj_var.)
%mergeDat(baseDat = adrp_ext_trans, keyDat = adsl_ext    , by = &subj_var.)

DATA adrp_ext_trans;
    SET adrp_ext_trans;
    IF missing(hys) THEN hys = 0;
    IF missing(os)  THEN os  = 0;
RUN;


%set_titles_footnotes(
    tit1 = "Table: Reproductive and menstrual history &saf_label."
  , ftn1 = "(a) Based on Medical History. PTs considered for hysterectomy are: Hysterectomy, Hysterosalpingectomy, Hysterosalpingo-oophorectomy and Radical hysterectomy."
  , ftn2 = "(b) Based on Medical History. PTs considered for oophorectomy are: Hysterosalpingo-oophorectomy, Oophorectomy, Oophorectomy bilateral, Salpingo-oophorectomy, Salpingo-oophorectomy bilateral, Salpingo-oophorectomy unilateral."
  , ftn3 = "Number of pregnancies, number of births, duration of being amenorrheic have not been collected in SWITCH-1."
);

%desc_freq_tab(
    data     = adrp_ext_trans
  , var      = pregnn pregnc brthn brthc amenlen hys os
  , var_freq = pregnc brthc hys os
  , data_n   = adsl_ext(WHERE=(&saf_cond.))
  , basepct  = N_CLASS
);



%endprog;
