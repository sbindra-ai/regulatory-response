/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adsl_iss_smpsz);
/*
 * Purpose          : Study sample sizes by study and region (all enrolled subjects)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        :  erjli (Yosia Hadisusanto) / date: 26FEB2024
 * Reference prog   :
 ******************************************************************************/

%LET mosto_param_class = %SCAN(&extend_var_disp_12_nt., 1, @);

%load_ads_dat(adsl_view, adsDomain = adsl);
%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_12_nt.
  , extend_rule = &extend_rule_disp_12_nt.
                @ missing(&mosto_param_class) # .
)

%set_titles_footnotes(
    tit1 = "Table: Study sample sizes by study and pooled region &enr_label."
  , ftn1 = "The number of subjects enrolled is the number of subjects who signed informed consent. For SWITCH-1 elinzanetant 40 mg, 80 mg, 160 mg are excluded."
  , ftn2 = "EZN 120 mg (week 1-12) and Placebo (week 1-12) refer to participants who were randomized to the respective treatment."
  , ftn3 = "Total (week 1-12) refers to all participants randomized to either EZN 120 mg or Placebo."
  , ftn4 = "21686 = SWITCH-1, 21651 = OASIS 1, 21652 = OASIS 2, 21810 = OASIS 3."
)

%dispositionpss(
    data      = adsl_ext(WHERE = (&enr_cond.))
  , by        = studyid region1n
  , groups    = "randfl='Y'"        *'Randomized'
                "saffl='Y'"         *'Valid for Safety'
  , groupstxt = Number of subjects
  , groupspct = YES
  , dates     = 'MIN(rficdt)'       *'Date of First Consent'
                'MAX(lvdt)'         *'Date of Last Visit'
  , totalby   = studyid region1n
  , maxlen    = 25
  , outdat    = calc_001
)

*< Updated needed for study level;
DATA calc_001;
    SET calc_001;
    IF &mosto_param_class. = 99999999 THEN &mosto_param_class. = &trt_tot_12.;
RUN;

%let _miss = %sysfunc(getoption(missing));
OPTIONS MISSING='';
    %mosto_param_from_dat(data = calc_001inp, var = config)
    %datalist(&config)
option missing="&_miss";
%symdel _miss;



%endprog;