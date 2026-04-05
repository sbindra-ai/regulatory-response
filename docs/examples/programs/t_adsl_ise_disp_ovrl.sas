/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adsl_ise_disp_ovrl);
/*
 * Purpose          : Create table: Disposition in overall study (all enrolled subjects)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gltlk (Rui Zeng) / date: 12JAN2024
 * Reference prog   :/var/swan/root/bhc/3427080/21651/stat/main01/dev/analysis/pgms/t_8_1_3_adds_disp_ovrl.sas (enpjp (Prashant Patel) / date: 20DEC2023)
 ******************************************************************************/

%LET mosto_param_class = &mosto_param_class_eff.;

%load_ads_dat(adsl_view, adsDomain = adsl, where = &enr_cond.)
%load_ads_dat(adds_view, adsDomain = adds, where = dscat in ('DISPOSITION EVENT' " ") and dsscat ne 'INFORMED CONSENT', keep = studyid usubjid dscat dsscat epoch dsdecod dsnext aphase dssubdec, adslVars =  );

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_eff.
  , extend_rule = &extend_rule_disp_eff.
);

%extend_data(
    indat       = adds_view
  , outdat      = adds_ext
  , var         = &extend_var_disp_eff.
  , extend_rule = &extend_rule_disp_eff.
);

DATA adsl_ext2;
    SET adsl_ext;
    IF &mosto_param_class. = 'SCRNFAIL' THEN &mosto_param_class. =''; *Do not display Screen failure column;
RUN;

DATA fup;
    SET adds_ext (WHERE = (epoch IN ("FOLLOW-UP" "POST-TREATMENT")));
    KEEP studyid usubjid fup;
    fup = 1;
RUN;

DATA disc;
    SET adds_ext (WHERE = (dssubdec = "STOP REGULAR SCHEDULED CONTACT" AND epoch="TREATMENT"));
    KEEP studyid usubjid disc;
    disc=1;
RUN;

DATA final;
    MERGE adsl_ext2(IN=a) fup(IN=b) disc(IN=d);
    BY studyid usubjid;
    IF a;
    IF NOT b AND NOT d THEN fup=0;
    %M_PropIt(Var=dcsreas);
RUN;

%set_titles_footnotes(
    tit1 = "Table: Disposition in overall study &enr_label."
  , ftn1 = 'Number of subjects enrolled is the number of subjects who signed informed consent.'
  , ftn2 = "&foot_placebo_ezn."
  , ftn3 = 'Definition of completed study = completed all phases of the study including the last visit.'
);

ODS ESCAPECHAR="^";

%disposition(
    data            = final
  , groups          = 'enrlfl   = "Y"'             * 'Enrolled'
                      'randfl   = "Y"'             * 'Randomized'
                      'exnyovln = 1'               * 'Treated'
                      'complfl  = "Y"'             * 'Completed study'
                      'complfl  = "N" and dcsreas_prop eq " "  and fup=1'             * 'Did not complete study treatment but completed post-treatment phase/follow-up'
  , groupstxt       = Number of subjects
  , discontinued    = (complfl  = "N" and dcsreas ne " ") or  (complfl  = "N" and dcsreas_prop eq " " and fup=0)
  , discontinuedtxt = Did not complete study
  , reason          = dcsreas_prop
  , code99x         = NO
  , freeline        =
  , total           = YES
)

%endprog;