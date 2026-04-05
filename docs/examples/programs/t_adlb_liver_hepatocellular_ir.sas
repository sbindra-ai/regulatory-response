/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adlb_liver_hepatocellular_ir);
/*
 * Purpose          : Number of subjects with potential Hepatocellular DILI by integrated analysis treatment group up to week xx (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gdcpl (Derek Li) / date: 20MAY2024
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : eqczz (Petri Pulkkinen) / date: 28MAY2024
 * Reason           : 1) Select first assessment of maximum value
 *                    2) Update the selection of dates in case maximum ALT and AST are
 *                    equal: we should prefer the ALT/AST date which is before maximum
 *                    bilirubin and closest to bilirubin measurement.
 ******************************************************************************/
/* Changed by       : eqczz (Petri Pulkkinen) / date: 30MAY2024
 * Reason           : Add space to footnote
 ******************************************************************************/
/* Changed by       : eqczz (Petri Pulkkinen) / date: 31MAY2024
 * Reason           : extend_rule_disp_12_52_a is already in use - name changed to
 *                    extend_rule_disp_12_52_lab
 ******************************************************************************/


%LET mosto_param_class = %scan(&extend_var_disp_12_ezn_52_a, 1, '@');

* Load and extend data;
%load_ads_dat(
    adlb_view
  , adsDomain = adlb
  , where     = paramcd in ('SGOTSP', 'SGPTSP','BILITOSP','ALKPHOSP') and &post_baseline_cond.
  , adslWhere = &saf_cond.
)
;
%load_ads_dat(adsl_view, adsDomain = adsl, where = &saf_cond.)
;

%extend_data(
    indat       = adlb_view
  , outdat      = adlb_ext
  , var         = &extend_var_disp_12_ezn_52_a.
  , extend_rule = &extend_rule_disp_12_52_anofl.
)
;

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , subj_var    = USUBJID
  , var         = &extend_var_disp_12_ezn_52_a.
  , extend_rule = &extend_rule_disp_12_52_lab.
)
;

* Prepare data;
%LET by_vars = studyid usubjid &mosto_param_class.;

DATA adlb_switch;
    SET adlb_ext;
    IF n(aval, anrhi) = 2 THEN aval_normalized = aval/anrhi;* Normalize;
RUN;

PROC SORT DATA = adlb_switch;
    BY &by_vars. paramcd aval_normalized DESCENDING adt;
RUN;

* Select maximum value by parameter;
DATA adlb_max;
    SET adlb_switch;
    BY &by_vars. paramcd;
    IF LAST.paramcd;
    FORMAT paramcd;
RUN;

* Transpose;
PROC TRANSPOSE DATA = adlb_max OUT = adlb_trans;
    BY &by_vars.;
    VAR aval_normalized;
    ID paramcd;
RUN;
PROC TRANSPOSE DATA = adlb_max OUT = adlb_trans_adt PREFIX = dt_;
    BY &by_vars.;
    VAR adt;
    ID paramcd;
RUN;

* Merge transposed;
DATA adlb_final(DROP = apu diff_dt_bili_sgotsp diff_dt_bili_sgptsp);
    MERGE adlb_trans    (IN = a DROP=_:)
          adlb_trans_adt(IN = b DROP=_:);
    BY &by_vars. ;
    IF a;

    * Days from bilirubin to ALT and AST ;
    IF not missing(dt_bilitosp) THEN DO;
        IF not missing(dt_sgotsp) THEN diff_dt_bili_sgotsp=dt_bilitosp-dt_sgotsp;
        IF not missing(dt_sgptsp) THEN diff_dt_bili_sgptsp=dt_bilitosp-dt_sgptsp;
    END;

    * Select maximum of ALT and AST;
    IF n(sgotsp, sgptsp) = 2
       THEN xvar = max(sgotsp, sgptsp);
    ELSE xvar = coalesce(sgotsp, sgptsp);

    * Select corresponding date;
    *< AST > ALT - take date of AST ;
    IF sgotsp > sgptsp THEN DO;
        xvar_dt = dt_sgotsp;
        apu=1;
    END;
    *< ALT > AST - take date of ALT ;
    IF sgotsp < sgptsp THEN DO;
        xvar_dt = dt_sgptsp;
        apu=2;
    END;
    *< ALT = AST - take the date before bilirubin which is closest to bilirubin   ;
    IF sgotsp = sgptsp THEN DO;
        *< bilirubin date is before both ALT/AST dates or at ALT/AST date - take minimum of ALT or AST (Closest to bilirubin);
        IF max(diff_dt_bili_sgotsp,diff_dt_bili_sgptsp)=<0 THEN DO;
            xvar_dt = min(dt_sgotsp,dt_sgptsp);
            apu=3;
        END;
        *< bilirubin date is after both of one the ALT/AST dates - take maximum of ALT or AST (Closest to bilirubin);
        IF max(diff_dt_bili_sgotsp,diff_dt_bili_sgptsp)>0  THEN DO;
            xvar_dt = max(dt_sgotsp,dt_sgptsp);
            IF min(diff_dt_bili_sgotsp,diff_dt_bili_sgptsp)<0 THEN DO;
                xvar_dt = min(dt_sgotsp,dt_sgptsp);
            END;
            apu=4;
        END;
    END;

    * A potential Hy's Law case (red circle) was defined as having any post-baseline total bilirubin equal to or exceeding 2 x ULN within 30 days
      after a post-baseline ALT or AST equal to or exceeding 3 x ULN, and ALP <2 x ULN (note ALP values are not circled).;
    IF (xvar >= 3) AND (bilitosp >= 2 AND xvar_dt <= dt_bilitosp < xvar_dt + 30) AND alkphosp < 2 THEN flag = 1;
    format xvar_dt date9.;
RUN;

%m_add_time_window_lab(indat = adsl_ext, outdat = adsl_ext);

DATA adlb_final;
    SET adlb_final;
    format &mosto_param_class. _trtgrp_split.  event $10.;
    if (xvar>=3 and BILITOSP>=2) then event='AA';
    if  (xvar<3 and BILITOSP>=2) then event='BB';
    if (xvar>=3 and BILITOSP<2) then event='CC';
    aseq=_n_;
    ADSNAME='ADLB';
RUN;

*Potential Hy's Law (right upper)
any post-baseline total bilirubin equal to or exceeding 2 x ULN &
a post-baseline ALT or AST equal to or exceeding 3 x ULN
*;

*Cholestasis (left upper)
any post-baseline total bilirubin equal to or exceeding 2 x ULN &
a post-baseline ALT or AST < 3 x ULN---Not there in LB data *;

*Temple's corollary (right lower):
a post-baseline ALT or AST equal to or exceeding 3 x ULN &
any post-baseline total bilirubin < 2 x ULN
*;

%macro _m_rd(indat=,arms=,week=);
    *< Table;
    %set_titles_footnotes(
        tit1 = "Table: Number of subjects with potential Hepatocellular DILI by integrated analysis treatment group up to week &week. &saf_label."
      , ftn1 = "This table is generated using maximum liver test abnormalities in the post-baseline period. &_week26. N = number of participants in integrated analysis treatment group, n = number of participants meeting criteria."
      , ftn2 = "Unscheduled visits were included in the analysis. DILI=Drug-Induced Liver Injury."
      , ftn3 = "Study size and exposure-adjusted IRs are calculated as following: For each study and treatment group, the exposure-adjusted incidence (= number of participants with event / sum of exposure days) is multiplied by the proportion of the study exposure to the total exposure across studies. Results are then added up across all studies for each treatment group."
      , ftn4 = "Where sum of exposure days = sum of time to first event for participants if an event occurred + sum of treatment duration with time after treatment up to end of observation for participants without event."
      , ftn5 = "End of observation is defined as post-baseline as defined in the IA SAP."
      , ftn6 = "Results are provided per 100 person-years, where one person-year is defined as 365.25 days."
      , ftn7 = "*IRs are study size adjusted incidence rates according to Crowe et al (2016)."
    )
    ;
    data _used_adlb;
        set &indat.;
        if &mosto_param_class. in (&arms);
    RUN;

    data _used_adsl;
        set adsl_ext;
        if &mosto_param_class. in (&arms);
        format &mosto_param_class. _trtgrp_split.;
    RUN;

    %overview_tab(
        data      = _used_adlb
      , data_n    = _used_adsl
      , total     = no
      , groups    = 'event="AA"' * "Potential Hy's Law (right upper)"
                 'event="BB"' * 'Cholestasis (left upper)'
                 'event="CC"' * "Temple's corollary (right lower)"
      , groupstxt = Quadrant
      , outdat    = out_table
    )
    ;
    /*
    data out_table;
        set out_table(rename=(_name_=_name_old));
        format _name_ $250.;
        if _name_old="Potential Hy's Law (right upper)" then _name_='AA';
        if _name_old="Cholestasis (left upper)" then _name_='BB';
        if _name_old="Temple's corollary (right lower)" then _name_='CC';
    RUN;
    */
    data _mm_subject;
        set _mm_subject;
        if upcase(_mergevar1_)="POTENTIAL HY'S LAW (RIGHT UPPER)" then _mergevar1_='event="AA"';
        if upcase(_mergevar1_)="CHOLESTASIS (LEFT UPPER)" then _mergevar1_='event="BB"';
        if upcase(_mergevar1_)="TEMPLE'S COROLLARY (RIGHT LOWER)" then _mergevar1_='event="CC"';
    RUN;

    %m_overview_100_patyears(
        indat          = _used_adlb(WHERE=(not missing(event)))
      , indat_adsl     = _used_adsl
      , indat_mosto    = out_table
      , censordt       = enddt
      , startdt        = startdt
      , enddt          = enddt
      , event_var      = event
      , adt            = xvar_dt
      , outdat         = overall_eair_out
      , debug          = Y
    );
    /*
    ** Remove EAIR for some action taken categories;
    DATA overall_eair_out;
        SET overall_eair_out;
        IF strip(_name_) IN  ('DOSE NOT CHANGED' 'DRUG INTERRUPTED' 'NOT APPLICABLE') THEN DO;
            IF NOT missing(eair_1) THEN _col_01 = tranwrd(_col_01, vvalue(eair_1), ' ');
            IF NOT missing(eair_2) THEN _col_02 = tranwrd(_col_02, vvalue(eair_2), ' ');
        END;
    RUN;
    */

        %mosto_param_from_dat(data = overall_eair_outinp, var = config)
        %datalist(&config)

%MEND;

%let _week26=;
%_m_rd(indat=adlb_final,arms=1 2,week=12);

%let _week26=At any time post-baseline for OASIS 3, the event onset is up to day 182 (inclusive) for EZN 120 mg (week 1-26) and Placebo (week 1-26).;
%_m_rd(indat=adlb_final,arms=4 5,week=26);

%let _week26=;
%_m_rd(indat=adlb_final,arms=6 7,week=52);

%endprog()
;
