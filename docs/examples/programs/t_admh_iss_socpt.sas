/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_admh_iss_socpt);
/*
 * Purpose          : Medical history: number of subjects with findings by primary system organ class and preferred term SAF
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : erjli (Yosia Hadisusanto) / date: 26FEB2024
 * Reference prog   :
 ******************************************************************************/

%let mosto_param_class = %scan(&extend_var_disp_12_52_a., 1, '@');

%load_ads_dat(adsl_view, adsDomain = adsl);

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_12_52_a.
  , extend_rule = &extend_rule_disp_12_52_a.
);

%load_ads_dat(admh_view, adsDomain = admh);

%extend_data(
    indat       = admh_view
  , outdat      = admh_ext
  , var         = &extend_var_disp_12_52_a.
  , extend_rule = &extend_rule_disp_12_52_a.
);

%MACRO m_medhis(by=, by_title=);

    %set_titles_footnotes(
        tit1 = "Table: Medical history: number of subjects with findings by primary system organ class and preferred term &by_title. &saf_label."
      , ftn1 = "A subject is counted only once within each primary SOC/ preferred term."
      , ftn2 = "Medical history terms are sorted by alphabetical order of the SOC and by frequency of the PTs based on EZN 120 mg (week 1-12)."
      , ftn3 = "Participants are presented in more than one treatment groups."
    );

    %LET MOSTOCALCPERCWIDTH=NO;
    %insertOptionRTF(namevar = _levtxt, width = 45mm, keep = n, overwrite = n)
    %insertOptionRTF(namevar = _t_1, width = 40mm, keep = n, overwrite = n)
    %insertOptionRTF(namevar = _t_2, width = 31mm, keep = n, overwrite = n)
    %insertOptionRTF(namevar = _t_3, width = 33mm, keep = n, overwrite = n)
    %insertOptionRTF(namevar = _t_4, width = 40mm, keep = n, overwrite = n)
    %insertOptionRTF(namevar = _t_5, width = 31mm, keep = n, overwrite = n)

    %incidence_print(
        data        = admh_ext(WHERE=(mhoccur NE 'N'))
      , data_n      = adsl_ext(WHERE=(&saf_cond.))
      , page        = &by.
      , var         = mhbodsys mhdecod
      , triggercond = mhdecod ne ' '
      , sortorder   = FREQA
      , frqvar      = 1     /* sort by descending frequency in EZN 120 mg (week 1-12) */
      , evlabel     = Primary system organ class#   Preferred term#   MedDRA version &v_meddra.
      , anytxt      = Number (%) of subjects with at least one medical history finding
      , together    =
    )

%MEND;

%m_medhis;

%endprog;