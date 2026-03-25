/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adex_iss_durn);
/*
 * Purpose          : Create table: Treatment duration by integrated analysis treatment group (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gltlk (Rui Zeng) / date: 29FEB2024
 * Reference prog   :
 ******************************************************************************/

** >>> START: Treatment dose per day by integrated analysis treatment group (safety analysis set);
%LET mosto_param_class = %scan(&extend_var_disp_12_26_52_nt_a., 1, '@');

*get data and select only Safety patients;
%load_ads_dat(adsl_view, adsDomain = adsl, where = &saf_cond.)
%load_ads_dat(
    adex_view
  , adsDomain = adex
  , adslWhere = &saf_cond.
  , where     = paramcd = 'DURW' and aval ne .
)

*Extend treatment group as needed;
%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_12_26_52_nt_a.
  , extend_rule = &extend_rule_disp_12_26_52_nt_a.
);

%extend_data(
    indat       = adex_view
  , outdat      = adex_ext
  , var         = &extend_var_disp_12_26_52_nt_a.
  , extend_rule = &extend_rule_disp_exposure.
);

DATA adex_ext;
    SET adex_ext;
    LABEL aval     = "Duration of treatment (weeks)"
          avalca1n = "Treatment duration categories (disjunct)";
RUN;

DATA adex_cum;
    SET adex_ext;
    ATTRIB exposure FORMAT=_exp. LABEL='Treatment duration categories (cumulative)';

    IF missing(aval) THEN DO; CALL missing(exposure); OUTPUT; END;
    IF aval*7 > 0 THEN DO; exposure =  1; OUTPUT; END;
    IF aval >= 4 THEN DO; exposure =  4; OUTPUT; END;
    IF aval >= 12 THEN DO; exposure =  12; OUTPUT; END;
    IF aval >= 23 THEN DO; exposure =  23; OUTPUT; END;
    IF aval >= 50 THEN DO; exposure =  50; OUTPUT; END;
RUN;

%set_titles_footnotes(
    tit1 = "Table: Treatment duration by integrated analysis treatment group &saf_label."
    , ftn1 = "Overall duration of treatment is defined as the number of days from the day of first study drug intake up to and including the day of last study drug intake. (*ESC*)n The dates of first/last study drug refer to the first 12 weeks for"
    , ftn2 = "<cont>treatment groups EZN 120 mg (week 1-12) and Placebo (week 1-12), first 26 weeks for treatment groups EZN 120 mg (week 1-26) and Placebo (week 1-26) and to the complete 52 weeks for EZN 120 mg (week 1-52) and Placebo (week 1-52)."
    , ftn3 = "Planned duration of treatment for SWITCH-1, OASIS 1, 2 and 3 is 12, 26, 26 and 52 weeks, respectively. (*ESC*)n For the integrated analysis, from SWITCH-1, only the treatment groups EZN 120 mg and Placebo are included."
    , ftn4 = "Switchers from placebo (week 1-12) to elinzanetant (week 13-26) in OASIS 1 and 2 are presented in columns Placebo (week 1-12), Placebo (week 1-26), EZN 120 mg (week 1-26), EZN 120 mg (week 1-52) and Placebo (week 1-52)."
    , ftn5 = "<cont>For those participants, the duration of treatment of the placebo-treated period is presented in the columns Placebo (week 1-12), Placebo (week 1-26) and Placebo (week 1-52); the duration of treatment of the elinzanetant-treated period"
    , ftn6 = "<cont>is presented in EZN 120 mg (week 1-26) and EZN 120 mg (week 1-52). (*ESC*)n Duration of treatment is based on the data collected via the eCRF. For OASIS 1 and 2, Week 1-12 represents the placebo controlled period of the study and"
    , ftn7 = "<cont>Week 13-26 represents the period at which all participants are treated with elinzanetant. For OASIS 3, Week 1-12 is defined from start of study treatment until (T3 visit date -1) and Week 13-52 as T3 visit date onwards until end of"
    , ftn8 = "<cont>study treatment intake. Week 1-26 is defined from start of study treatment until day 182 (inclusive)."
    , ftn9 = " According protocol, the Visit T5 was allowed to be Week 24 - 7 days (i.e. at day 162 to 168) and Visit T9/EoT was allowed to be Week 52 - 14 days (i.e. at day 351-364) for OASIS 3. (*ESC*)n &foot_sd."
);

*Treatment duration (weeks), Treatment duration categories (disjunct);
%desc_freq_tab(
    data         = adex_ext
  , var          = aval avalca1n
  , data_n       = adsl_ext
  , basepct      = n_class
  , stat         = n nmiss mean std min median max
  , round_factor = 0
  , outdat       = out
)

*Treatment duration categories (cumulative);
%desc_freq_tab(
    data         = adex_cum
  , var          = aval exposure  /*use AVAL to keep the same outdat structure as above macro call*/
  , data_n       = adsl_ext
  , basepct      = n_class
  , stat         = n nmiss mean std min median max
  , outdat       = out_2
)

DATA out;
    SET out(IN=a) out_2(IN=b);
    IF b THEN DO;
        IF upcase(_var_) = 'AVAL' THEN DELETE;
        _posi_ = _posi_ + 100;
    END;
RUN;

%mosto_param_from_dat(data = outinp, var = varlist)
%datalist(&varlist.)

** <<< END: Create table - Treatment dose per day by integrated analysis treatment group (safety analysis set);

%endprog();
