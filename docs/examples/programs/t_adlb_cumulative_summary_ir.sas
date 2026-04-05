/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adlb_cumulative_summary_ir);
/*
 * Purpose          : Number of subjects and study size and exposure-adjusted incidence rate by cumulative hepatic safety laboratory parameter category up to week <<12/26/52>> (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gdcpl (Derek Li) / date: 22MAY2024
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : erjli (Yosia Hadisusanto) / date: 23MAY2024
 * Reason           : Update indat for %m_overview_100_patyears2 to be _used_adlb_1
 ******************************************************************************/
/* Changed by       : evmqe (Endri Elnadav) / date: 28MAY2024
 * Reason           : Update ADSL
 ******************************************************************************/
/* Changed by       : eqczz (Petri Pulkkinen) / date: 31MAY2024
 * Reason           : extend_rule_disp_12_52_a is already in use - name changed to
 *                    extend_rule_disp_12_52_lab
 ******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 05SEP2024
 * Reason           : Removed todays updates - no change to prod
 ******************************************************************************/


%LET mosto_param_class = %scan(&extend_var_disp_12_ezn_52_a, 1, '@');

* Load and extend data;
%load_ads_dat(
    adlb_view
  , adsDomain = adlb
  , where     = paramcd in (&liver_param.) and &lb_avisit_selection.
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



DATA adlb_switch;
    SET adlb_ext(where=(paramcd ne 'GGT'));


RUN;

* Create AST or ALT;
DATA adlb_alt_ast;
    SET adlb_switch(WHERE = (paramcd IN ('SGOTSP' 'SGPTSP')));
    paramcd ='ALT_AST';
RUN;

DATA adlb_tab;
    SET adlb_switch
        adlb_alt_ast;
    ATTRIB param_label LABEL = 'Parameter' LENGTH = $100.;
    IF paramcd = 'SGPTSP'    THEN DO;
        _ord = 1;
        param_label = 'ALT';
    END;
    ELSE IF paramcd = 'SGOTSP'    THEN DO;
        _ord = 2;
        param_label = 'AST';
    END;
    ELSE IF paramcd = 'ALT_AST'   THEN DO;
        _ord = 3;
        param_label = 'ALT or AST';
    END;
    ELSE IF paramcd = 'BILITOSP'  THEN DO;
        _ord = 4;
        param_label = 'Total bilirubin';
    END;
    ELSE IF paramcd = 'ALKPHOSP'  THEN DO;
        _ord = 5;
        param_label = 'ALP';
    END;
    ELSE IF paramcd = 'PTINR'     THEN DO;
        _ord = 6;
        param_label = 'INR';
    END;

    ATTRIB avisit LABEL = 'Time interval' LENGTH = $200.;
    IF &post_baseline_cond. THEN DO;
        avisit = "At any time post-baseline";
        avisitn_new = 2;
    END;
    IF avisitn = 5 THEN delete;
RUN;

%m_add_time_window_lab(indat = adsl_ext, outdat = adsl_ext);


DATA adlb_final;
    SET adlb_tab;
    format &mosto_param_class. _trtgrp. ;


RUN;

%macro _m_rd(indat=,arms=,week=);
    *< Table;
    %set_titles_footnotes(
        tit1 = "Table: Number of subjects and study size and exposure-adjusted incidence rate by cumulative hepatic safety laboratory parameter category up to week &week. &saf_label."
      , ftn1 = "n = number of subjects with parameter assessment done at respective time point. &_week26."
      , ftn2 = "Unscheduled visits were included in the analysis. ULN = Upper Limit of Normal. AST = Aspartate Aminotransferase, ALT = Alanine Transferase, ALP = Alkaline Phosphatase, INR = International Normalized Ratio."
      , ftn3 = "Study size and exposure-adjusted IRs are calculated as following: For each study and treatment group, the exposure-adjusted incidence (= number of participants with event / sum of exposure days) is multiplied by the proportion of the study exposure to the total exposure across studies. Results are then added up across all studies for each treatment group."
      , ftn4 = "Where sum of exposure days = sum of time to first event for participants if an event occurred + sum of treatment duration with time after treatment up to end of observation for participants without event."
      , ftn5 = "End of observation is defined as post-baseline as defined in the IA SAP."
      , ftn6 = "Results are provided per 100 person-years, where one person-year is defined as 365.25 days."
      , ftn7 = "*IRs are study size adjusted incidence rates according to Crowe et al (2016)."
    )
    ;
    proc sql;
        create table toc as
               select distinct _ord,param_label
               from &indat.
               ;

    QUIT;

    data _null_;
        set toc end=last;
        call symputx('param'||cats(_n_),cats(param_label));
        if last then call symputx('nparm',cats(_n_));
    RUN;

    data _used_adlb;
        set &indat.;
        if &mosto_param_class. in (&arms);
        format event $10.;
        if not missing(aval) then event='A';
    RUN;

    data _used_adsl;
        set adsl_ext;
        if &mosto_param_class. in (&arms);
        format &mosto_param_class. _trtgrp.;
    RUN;

    %do ix=1 %to &nparm;
    data _used_adlb_1;
        set _used_adlb(where=(_ord=&ix.));
    RUN;


    %overview_tab(
        data      = _used_adlb_1
      , data_n    = _used_adsl
      , total     = no
      , groups    = 'event="A"'    *     'n'
                  '<DEL>'                *     'Category'
                  'crit8fl="Y"'          *     '>=1 x ULN'
                  'crit7fl="Y"'          *     '>=1.5 x ULN'
                  'crit6fl="Y"'          *     '>=2 x ULN'
                  'crit5fl="Y"'          *     '>=3 x ULN'
                  'crit4fl="Y"'          *     '>=5 x ULN'
                  'crit3fl="Y"'          *     '>=8 x ULN'
                  'crit2fl="Y"'          *     '>=10 x ULN'
                  'crit1fl="Y"'          *     '>=20 x ULN'
                  'crit11fl="Y"'         *     '>=1.5'
                  'crit12fl="Y"'         *     '>=2'
      , groupstxt =
      , n_group   = 1
      , outdat    = out_table
    )
    ;

    data _mm_subject;
        set _mm_subject;
        if upcase(_mergevar1_)="N" then _mergevar1_='event="A"';
        if upcase(_mergevar1_)=">=1 X ULN" then _mergevar1_='crit8fl="Y"';
        if upcase(_mergevar1_)=">=1.5 X ULN" then _mergevar1_='crit7fl="Y"';
        if upcase(_mergevar1_)=">=2 X ULN" then _mergevar1_='crit6fl="Y"';
        if upcase(_mergevar1_)=">=3 X ULN" then _mergevar1_='crit5fl="Y"';
        if upcase(_mergevar1_)=">=5 X ULN" then _mergevar1_='crit4fl="Y"';
        if upcase(_mergevar1_)=">=8 X ULN" then _mergevar1_='crit3fl="Y"';
        if upcase(_mergevar1_)=">=10 X ULN" then _mergevar1_='crit2fl="Y"';
        if upcase(_mergevar1_)=">=20 X ULN" then _mergevar1_='crit1fl="Y"';
        if upcase(_mergevar1_)=">=1.5" then _mergevar1_='crit11fl="Y"';
        if upcase(_mergevar1_)=">=2" then _mergevar1_='crit12fl="Y"';

    RUN;

    %* EVMQE Filter ADSL which has only measurement;
    PROC SORT NODUPKEY DATA = _used_adlb_1 (WHERE=(not missing(event)))
                       OUT  = _temp_subject;
      BY &subj_var.;
    RUN;
    DATA _used_adsl_1;
      MERGE _used_adsl
            _temp_subject (IN = _keep KEEP = &subj_var.);
      BY &subj_var.;
      IF _keep;
    RUN;

    %m_overview_100_patyears2(
        indat          = _used_adlb_1 (WHERE=(not missing(event)))
      , indat_adsl     = _used_adsl_1
      , indat_mosto    = out_table
      , censordt       = enddt
      , startdt        = startdt
      , enddt          = enddt
      , adt            = adt
      , outdat         = overall_eair_out&ix.
      , debug          = NO
    );

    data overall_eair_out&ix.;
        set overall_eair_out&ix.;
        _ord=&ix.;
        attrib param_label format=$40. label='Parameter';
        param_label="&&param&ix.";
    RUN;
    %end;

    data overall_eair_out;
        set %do i=1 %to &nparm.; overall_eair_out&i. %end;;
        attrib avisit format= $200. label='Time interval';
        avisit = "At any time post-baseline";
        IF _order_ = 1 THEN _name_ = strip(_name_);
        IF _ord NE 1 THEN CALL missing(avisit);

        if _ord in (1,2) then do;
            if _order_ in (4,5,11,12) then delete;
        END;
        if _ord in (3) then do;
            if _order_ in (3,4,5,11,12) then delete;
        END;
        if _ord in (4) then do;
            if _order_ in (4,6,9,10,11,12) then delete;
        END;
        if _ord in (5) then do;
            if _order_ in (3,7,8,9,10,11,12) then delete;
        END;
        if _ord in (6) then do;
            if _order_ in (3,4,5,6,7,8,9,10) then delete;
        END;

         _col_01=prxchange('s/(\()(\s{5,})(\d+.?\d+)?/$2 $3    $1 /',-1,_col_01);
         _col_01=prxchange('s/(\()\s+(N)/$1$2/',1,_col_01);
          _col_02=prxchange('s/(\()(\s{5,})(\d+.?\d+)?/$2 $3    $1 /',-1,_col_02);
          _col_02=prxchange('s/(\()\s+(N)/$1$2/',1,_col_02);
    RUN;

    data overall_eair_out;
        set overall_eair_out;
        if _n_=1 then do;
            call symputx('lb_1',strip(substr(_col_01,index(_col_01,'N')-2)));
            call symputx('lb_2',strip(substr(_col_02,index(_col_02,'N')-2)));
        END;

         if not missing(_col_01) then do;
            _col_01=strip(substr(_col_01,1,index(_col_01,'N')-3));
         end;


          if not missing(_col_02) then do;
             _col_02=strip(substr(_col_02,1,index(_col_02,'N')-3));
          end;

          IF strip(_name_) IN  ('n') THEN DO;
              IF NOT missing(eair_1) THEN _col_01 = tranwrd(_col_01, vvalue(eair_1), ' ');
              IF NOT missing(eair_2) THEN _col_02 = tranwrd(_col_02, vvalue(eair_2), ' ');
          END;
    RUN;

    data overall_eair_out;
        set overall_eair_out;
        label _col_01="%varlabel(overall_eair_out,_col_01) &lb_1"
              _col_02="%varlabel(overall_eair_out,_col_02) &lb_2"
              ;
        array _co[2] _col_01 _col_02;
        do i=1 to dim(_co);
            if not findc(strip(scan(_co[i],-1,' ')),')') and findc(_co[i],'(') then do;
                if length(strip(scan(_co[i],1,'(')))=3 then
                     _co[i]=substr(_co[i],1,15)||'      '||strip(scan(_co[i],-1,' '));
                if length(strip(scan(_co[i],1,'(')))=2 then
                     _co[i]=substr(_co[i],1,15)||'        '||strip(scan(_co[i],-1,' '));
                if length(strip(scan(_co[i],1,'(')))=1 then
                     _co[i]=substr(_co[i],1,15)||'         '||strip(scan(_co[i],-1,' '));
            END;
            if not findc(strip(scan(_co[i],-1,' ')),')') and not findc(_co[i],'(')
             and scan(_co[i],1,' ') ne scan(_co[i],-1,' ') then do;
                _co[i]=substr(_co[i],1,5)||'                       '||strip(scan(_co[i],-1,' '));
            END;
        END;
    RUN;


    data overall_eair_outinp;
        set overall_eair_out1inp;
        if keyword='DATA' then value='overall_eair_out';
        if keyword='BY' then value='_ord avisit param_label _order_ fline _name_';
        if keyword='ORDER' then value='_ord  _order_ fline ';
        IF keyword = "FREELINE" THEN value="param_label";
        IF keyword = "TOGETHER" THEN value="param_label";
    RUN;

        %mosto_param_from_dat(data = overall_eair_outinp, var = config)
        %datalist(&config);

%MEND;

%let _week26=;
%_m_rd(indat=adlb_final,arms=1 2,week=12);

%let _week26=At any time post-baseline for OASIS 3, the event onset is up to day 182 (inclusive) for EZN 120 mg (week 1-26) and Placebo (week 1-26).;
%_m_rd(indat=adlb_final,arms=4 5,week=26);

%let _week26=;
%_m_rd(indat=adlb_final,arms=6 7,week=52);

%endprog()
;