/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adlb_combine_sum_base_ir);
/*
 * Purpose          : Number of subjects by combined hepatic safety laboratory categories relative to baseline up to week <<12/26/52>> (safety analysis set)
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
/* Changed by       : erjli (Yosia Hadisusanto) / date: 24MAY2024
 * Reason           : Update
 ******************************************************************************/
/* Changed by       : evmqe (Endri Elnadav) / date: 27MAY2024
 * Reason           : Update
 ******************************************************************************/
/* Changed by       : eqczz (Petri Pulkkinen) / date: 31MAY2024
 * Reason           : extend_rule_disp_12_52_a is already in use - name changed to
 *                    extend_rule_disp_12_52_lab
 ******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 05SEP2024
 * Reason           : Add comment and use &mosto_param_class. instead of trt01an
 ******************************************************************************/

%LET mosto_param_class = %scan(&extend_var_disp_12_ezn_52_a, 1, '@');

* Load and extend data;
%load_ads_dat(adlb_view, adsDomain = adlb , where = 95009000 le paramn le 95013000 and avisitn>5, adslWhere = &saf_cond.); * Select CCRIT 9 to 13;
%load_ads_dat(adsl_view, adsDomain = adsl, where = &saf_cond.);

%extend_data(
    indat       = adlb_view
  , outdat      = adlb_ext
  , var         = &extend_var_disp_12_ezn_52_a.
  , extend_rule = &extend_rule_disp_12_52_anofl.
);


%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , subj_var    = USUBJID
  , var         = &extend_var_disp_12_ezn_52_a.
  , extend_rule = &extend_rule_disp_12_52_lab.
);


DATA adlb_0;
    SET adlb_ext;
    format &mosto_param_class. _trtgrp.;
    FORMAT critflall $x_ny.;
    attrib critall format = $200. label = 'Category';
    critall   = put(paramcd,$x_lbpar.);
    critflall = avalc;
run;

**?to keep only one record for each usubjid, if have Y, keep Y, otherwise keep N;
DATA adlb_0_n
     adlb_0_y;
    SET adlb_0;
    IF critflall = 'Y' THEN OUTPUT  adlb_0_y;
                       ELSE OUTPUT  adlb_0_n;
RUN;
proc sort data=adlb_0_y;
    by studyid usubjid paramcd adt critflall;
RUN;
DATA adlb_0_y;
    SET adlb_0_y;
    BY studyid usubjid paramcd adt;
    IF FIRST.paramcd;
RUN;


DATA adlb_switch;
    SET adlb_0_n adlb_0_y;
RUN;
proc sort data=adlb_switch;
    by studyid usubjid paramcd critflall;
RUN;

data adlb_switch;
    set adlb_switch;
    by studyid usubjid paramcd;
    if last.paramcd;
RUN;

%m_add_time_window_lab(indat = adsl_ext, outdat = adsl_ext);


%macro _m_rd(indat=,arms=,week=, triggercond=critflall = 'Y');
    *< Table;
    %set_titles_footnotes(
        tit1 = "Table: Number of subjects by combined hepatic safety laboratory categories relative to baseline up to week &week. &saf_label."
      , ftn1 = "n = number of subjects with parameter assessments done at baseline and at post-baseline."
      , ftn2 = "Unscheduled visits were included in the analysis. &_week26."
      , ftn3 = "AST = Aspartate Aminotransferase, ALT = Alanine Transferase, ALP = Alkaline Phosphatase."
      , ftn4 = "Study size and exposure-adjusted IRs are calculated as following: For each study and treatment group, the exposure-adjusted incidence (= number of participants with event / sum of exposure days) is multiplied by the proportion of the study exposure to the total exposure across studies. Results are then added up across all studies for each treatment group."
      , ftn5 = "Where sum of exposure days = sum of time to first event for participants if an event occurred + sum of treatment duration with time after treatment up to end of observation for participants without event."
      , ftn6 = "End of observation is defined as post-baseline as defined in the IA SAP."
      , ftn7 = "Results are provided per 100 person-years, where one person-year is defined as 365.25 days."
      , ftn8 = "*IRs are study size adjusted incidence rates according to Crowe et al (2016)."
    )
    ;



    %MACRO _loop (paramn = , out = );
    data _used_adlb;
        set &indat.;
        if &mosto_param_class. in (&arms);
        IF paramn = &paramn.;
        format &mosto_param_class. _trtgrp.;
        astdt=adt;
    RUN;

    data _used_adsl;
        set adsl_ext;
        if &mosto_param_class. in (&arms);
        format &mosto_param_class. _trtgrp.;
    RUN;

    %* EVMQE Filter ADSL which has only measurement;
    %* Attention - EREIU: this gives a N not based on all SAF subjects - will be updated below;
    PROC SORT NODUPKEY DATA = _used_adlb
                       OUT  = _temp_subject;
      BY &subj_var.;
    RUN;
    DATA _used_adsl_1;
      MERGE _used_adsl
            _temp_subject (IN = _keep KEEP = &subj_var.);
      BY &subj_var.;
      IF _keep;
    RUN;


    %m_inc_100_patyears(
        indat       = _used_adlb    (WHERE=(&triggercond.))
      , indat_adsl  = _used_adsl_1
      , class       = &mosto_param_class.
      , censordt    = enddt
      , startdt     = startdt
      , var         = paramn
      , triggercond = &triggercond.
      , evlabel     = AA
      , anytxt      = TO_DELETE
      , outdat      = out_tt
      , debug       = NO
    );

    %freq_tab(
        data     = _used_adlb
      , data_n   =
      , var      = critflall
      , subject  = usubjid
      , by       = paramn critall
      , total    = no
      , order    = paramn
      , basepct  = n
      , hlabel   = yes
      , complete = all
      , outdat   = out_table
    );
    DATA out_table_ori;
        SET out_table;
    RUN;


    proc sort data=out_tt out=out_tt1(rename=(_col_01=a _col_02=b));
        by paramn;
        where not missing(paramn);
    RUN;

    data out_tt1;
        SET out_tt1;
        &triggercond.;
    RUN;

    proc sort data=out_table out=out_table1;
        by paramn critflall;
    RUN;

    data out_table2;
        merge out_table1 out_tt1(keep=paramn critflall a b eair_1 eair_2);
        by paramn critflall;

    RUN;

    data out_table3;
        set out_table2;
        if _N_ = 1 then
        do;
          retain ExpressionID;
          pattern = "/\s{10}/";
          ExpressionID = prxparse(pattern);
        end;
        call prxsubstr(ExpressionID, a, _st1, _len);
        if _st1 ^= 0 then  do;
          _col_01=cats(_col_01)||substr(a,_st1);
        end;
        call prxsubstr(ExpressionID, b, _st2, _len);
        if _st2 ^= 0 then  do;
          _col_02=cats(_col_02)||substr(b,_st2);
        end;

        IF strip(critflall) not IN  ('Y') THEN DO;
            IF NOT missing(eair_1) THEN _col_01 = tranwrd(_col_01, vvalue(eair_1), ' ');
            IF NOT missing(eair_2) THEN _col_02 = tranwrd(_col_02, vvalue(eair_2), ' ');
        END;

    RUN;

    PROC SQL NOPRINT;
          SELECT COUNT(DISTINCT &subj_var.) INTO: lb_1 FROM _used_adsl WHERE &mosto_param_class. IN (1 4 6);
          SELECT COUNT(DISTINCT &subj_var.) INTO: lb_2 FROM _used_adsl WHERE &mosto_param_class. IN (2 5 7);
    QUIT;
    %LET lb_1 = &lb_1;
    %LET lb_2 = &lb_2;

    data out_table99_&paramn.;
       set out_table3;
       label _col_01="%varlabel(out_table,_col_01) (N=&lb_1)# n(%)                   IR*(100 person-years)"
             _col_02="%varlabel(out_table,_col_02) (N=&lb_2)# n(%)                   IR*(100 person-years)"
             ;

       _col_01 = SCAN(_col_01, 1, 'N');
       _col_02 = SCAN(_col_02, 1, 'N');
    RUN;
    %MEND;

    %_loop (paramn = 95009000);
    %_loop (paramn = 95010000);
    %_loop (paramn = 95011000);
    %_loop (paramn = 95012000);
    %_loop (paramn = 95013000);

    DATA out_table;
        SET out_table99_:;
    RUN;




    %mosto_param_from_dat(data =out_tableinp, var = config)
    %datalist(&config)
%MEND;

%let _week26=;
%_m_rd(indat=adlb_switch,arms=1 2,week=12);

%let _week26=For OASIS 3, the event onset is up to day 182 (inclusive) for EZN 120 mg (week 1-26) and Placebo (week 1-26).;
%_m_rd(indat=adlb_switch,arms=4 5,week=26);

%let _week26=;
%_m_rd(indat=adlb_switch,arms=6 7,week=52);

%endprog();