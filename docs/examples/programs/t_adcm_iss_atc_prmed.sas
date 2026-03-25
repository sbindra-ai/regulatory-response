/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adcm_iss_atc_prmed);
/*
 * Purpose          : Prior medication: number of subjects by ATC class (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gltlk (Rui Zeng) / date: 24JAN2024
 * Reference prog   :
 ******************************************************************************/

%LET mosto_param_class = %scan(&extend_var_disp_12_a., 1, '@');

%load_ads_dat(adcm_view, adsDomain = adcm, where = cmcat ne "MEDICATION OF INTEREST" and prefl = "Y")
%load_ads_dat(adsl_view, adsDomain = adsl);

%extend_data(
    indat       = adcm_view
  , outdat      = adcm_ext
  , var         = &extend_var_disp_12_a.
  , extend_rule = &extend_rule_disp_12_a.
);

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_12_a.
  , extend_rule = &extend_rule_disp_12_a.
);

**create one observation per class/subclass;
DATA adcm_ext2;
    SET adcm_ext;
    ARRAY c1 cmcl:;
    ARRAY c2 cmscl:;
    ATTRIB CLASS    LENGTH=$1 FORMAT=$atc. LABEL='ATC CLASS'
           SUBCLASS LENGTH=$3 FORMAT=$atc. LABEL='ATC SUBCLASS';
    DO i = 1 TO dim(c1);
        IF NOT missing(c1{i}) THEN DO;
            CLASS = c1{i};
            SUBCLASS = c2{i};
            OUTPUT;
        END;
    END;
RUN;

%set_titles_footnotes(
    tit1 = "Table: Prior medication: number of subjects by ATC class &saf_label."
  , ftn1 = "Medications taken before the start of study drug (regardless of when they ended) are included in this table."
  , ftn2 = "Multiple ATC codes per drug are possible. Therefore, the same drug may be counted in more than one category for an individual subject."
  , ftn3 = "Medications are displayed in alphabetical order by ATC class and in decreasing frequency by ATC subclass."
);

%incidence_print(
    data        = adcm_ext2
  , data_n      = adsl_ext(WHERE=(&saf_cond.))
  , var         = class subclass
  , triggercond = cmdecod ne ' '
  , sortorder   = FREQA
  , evlabel     = ATC CLASS#   SUBCLASS#      WHO-DD Version &v_whodd.
  , frqvar      = 1     /* sort by descending frequency in EZN 120 mg (week 1-12) */
  , anytxt      = Number (%) of subjects who took at least one medication before start of study drug
)

%endprog;