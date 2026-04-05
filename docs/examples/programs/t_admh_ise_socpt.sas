/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_admh_ise_socpt);
/*
 * Purpose          : Medical history: number of subjects with findings by primary system organ class and preferred term  (full analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gdcpl (Derek Li) / date: 16FEB2024
 * Reference prog   :
 ******************************************************************************/


%macro mh();
    %LET mosto_param_class = &mosto_param_class_eff.;

    %load_ads_dat(
        adsl_view
      , adsDomain = adsl
      , where     = &fas_cond.
    );
    %extend_data(
        indat       = adsl_view
      , outdat      = adsl_ext
      , var         = &extend_var_disp_eff.
      , extend_rule = &extend_rule_disp_eff.
    );

    %load_ads_dat(
        admh_view
      , adsDomain = admh
      , where     = mhoccur ne 'N'
      , adslWhere = &fas_cond.
      , adslVars  = fasfl region1n race armcd
    );


    %extend_data(
        indat       = admh_view
      , outdat      = admh_ext
      , var         = &extend_var_disp_eff.
      , extend_rule = &extend_rule_disp_eff.
    );

    %set_titles_footnotes(
        tit1 = "Table: Medical history: number of subjects with findings by primary system organ class and preferred term &fas_label."
       ,ftn1 = "A subject is counted only once within each primary SOC/ preferred term."
       ,ftn2 = "Medical history terms are sorted by alphabetical order of the SOC and by frequency of the PTs."
       ,ftn3 = "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks."
    );


    %incidence_print(
        data        = admh_ext
      , data_n      = adsl_ext
      , var         = mhbodsys mhdecod
      , triggercond = mhterm ne ' '
      , total       = yes
      , sortorder   = FREQA
      , evlabel     = Primary system organ class#   Preferred term#   MedDRA version &v_meddra
      , anytxt      = Number (%) of subjects with at least one medical history finding
      , hsplit      = '#@'
      , together    =
    )


%mend;

%mh();


/* Use %endprog at the end of each study program */
%endprog();
