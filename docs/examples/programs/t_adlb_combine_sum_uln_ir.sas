/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adlb_combine_sum_uln_ir);
/*
 * Purpose          : Number of subjects by combined hepatic safety laboratory categories relative to ULN up to week xx (safety analysis set)
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
/* Changed by       : evmqe (Endri Elnadav) / date: 30MAY2024
 * Reason           : Correct IR calc
 ******************************************************************************/
/* Changed by       : eqczz (Petri Pulkkinen) / date: 30MAY2024
 * Reason           : Removing ** in footnotes for CCRIT4
 ******************************************************************************/
/* Changed by       : eqczz (Petri Pulkkinen) / date: 31MAY2024
 * Reason           : extend_rule_disp_12_52_a is already in use - name changed to
 *                    extend_rule_disp_12_52_lab
 ******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 10SEP2024
 * Reason           : Update treatment label displaying big N based on all SAF subjects from ADSL - stat request
 ******************************************************************************/

%LET mosto_param_class = %scan(&extend_var_disp_12_ezn_52_a, 1, '@');

* Load and extend data;
%load_ads_dat(adlb_view, adsDomain = adlb , where = 95001000 le paramn le 95008000 and avisitn>5, adslWhere = &saf_cond.); * Select CCRIT 1 to 8;
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



DATA adlb_switch;
    SET adlb_ext;
    format &mosto_param_class. _trtgrp_split.;
    Attrib avisit LABEL = 'Time interval' length = $200.;
    avisit = "At any time post-baseline";

    FORMAT critflall $x_ny.;
    attrib critall format = $200. label = 'Category';

    critall   = put(paramcd,$x_lbpar.);

    if paramcd = "CCRIT7" then critall = strip(critall) || " (a)";
/*    if paramcd = "CCRIT4" then critall = strip(critall) || "**";*/
    critflall = avalc;
RUN;

**?to keep only one record for each usubjid, if have Y, keep Y, otherwise keep N;
proc sort data=adlb_switch;
    by studyid usubjid paramcd critflall;
RUN;

data adlb_switch;
    set adlb_switch;
    by studyid usubjid paramcd;
    if last.paramcd;
RUN;


%m_add_time_window_lab(indat = adsl_ext, outdat = adsl_ext);

%macro _m_rd(indat=,arms=,week=);
    *< Table;
    %set_titles_footnotes(
        tit1 = "Table: Number of subjects by combined hepatic safety laboratory categories relative to ULN up to week &week. &saf_label."
      , ftn1 = "n = number of subjects with parameter assessment done at respective time point. &_week26."
      , ftn2 = '(a) as collected on the CRF page "Clinical Signs and Symptoms with elevated liver enzymes". Unscheduled visits were included in the analysis.'
      , ftn3 = "ULN = Upper Limit of Normal. AST = Aspartate Aminotransferase, ALT = Alanine Transferase, ALP = Alkaline Phosphatase."
      , ftn4 = "Study size and exposure-adjusted IRs are calculated as following: For each study and treatment group, the exposure-adjusted incidence (= number of participants with event / sum of exposure days) is multiplied by the proportion of the study exposure to the total exposure across studies. Results are then added up across all studies for each treatment group."
      , ftn5 = "Where sum of exposure days = sum of time to first event for participants if an event occurred + sum of treatment duration with time after treatment up to end of observation for participants without event."
      , ftn6 = "End of observation is defined as post-baseline as defined in the IA SAP."
      , ftn7 = "Results are provided per 100 person-years, where one person-year is defined as 365.25 days."
      , ftn8 = "*IRs are study size adjusted incidence rates according to Crowe et al (2016)."
    );


    %MACRO _loop(paramn = );

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
        indat       = _used_adlb
      , indat_adsl  = _used_adsl_1
      , class       = &mosto_param_class.
      , censordt    = enddt
      , startdt     = startdt
      , var         = paramn critflall
      , triggercond = not missing(critflall)
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
      , by       = avisit paramn critall
      , total    = no
      , order    = paramn
      , basepct  = n
      , hlabel   = yes
      , complete = all
      , outdat   = out_table
    );

    proc sort data=out_tt out=out_tt1(rename=(_col_01=a _col_02=b));
        by paramn critflall;
        where not missing(paramn);
    RUN;

    proc sort data=out_table out=out_table1;
        by paramn critflall;
    RUN;

    data out_table;
        merge out_table1 out_tt1(keep=paramn critflall a b eair_1 eair_2);
        by paramn critflall;

    RUN;

    data out_table;
        set out_table;
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

   data out_table;
     set out_table;

     if index(_col_01,'N') then do;
        _col_01=strip(substr(_col_01,1,index(_col_01,'N')-1));
     end;


      if index(_col_02,'N') then do;
         _col_02=strip(substr(_col_02,1,index(_col_02,'N')-1));
      end;
   run;

    %* --> Start EREIU: Big N shall be all SAF subjects from ADSL;

    PROC SQL NOPRINT;
          SELECT COUNT(DISTINCT &subj_var.) INTO: lb_1 FROM _used_adsl WHERE &mosto_param_class. IN (1 4 6);
          SELECT COUNT(DISTINCT &subj_var.) INTO: lb_2 FROM _used_adsl WHERE &mosto_param_class. IN (2 5 7);
    QUIT;
    %let lb_1 = &lb_1.;
    %let lb_2 = &lb_2.;

    %let _100pers_n_py =  n (%)                  IR* (100 person-years);
    %let lb_1          = N = &lb_1.) # &_100pers_n_py.; %put ------> &=lb_1;
    %let lb_2          = N = &lb_2.) # &_100pers_n_py.; %put ------> &=lb_2;

    *% --> End EREIU;

   data out_table99_&paramn.;
       set out_table;
       label _col_01="%varlabel(out_table,_col_01) (&lb_1"
             _col_02="%varlabel(out_table,_col_02) (&lb_2"
             ;
   RUN;

    %MEND;

    %_loop(paramn = 95001000);
    %_loop(paramn = 95002000);
    %_loop(paramn = 95003000);
    %_loop(paramn = 95004000);
    %_loop(paramn = 95005000);
    %_loop(paramn = 95006000);
    %_loop(paramn = 95007000);
    %_loop(paramn = 95008000);


    DATA out_table;
          SET out_table99_:;
    RUN;





    %LET MOSTOCALCPERCWIDTH=NO;

    %insertoptionrtf(namevar = avisit,  width = 80.0pt,  keep = n, overwrite = no);
    %insertoptionrtf(namevar = critall, width = 180pt, keep = n, overwrite = no);
    %insertoptionrtf(namevar = _varl_,  width = 21.0pt,  keep = n, overwrite = no);
    %insertoptionrtf(namevar = _col_01, width = 150.0pt,  keep = n, overwrite = no);
    %insertoptionrtf(namevar = _col_02, width = 150.0pt,  keep = n, overwrite = no);
    %mosto_param_from_dat(data =out_tableinp, var = config)
    %datalist(&config);

    %LET MOSTOCALCPERCWIDTH=optimal;
%MEND;

%let _week26=;
%_m_rd(indat=adlb_switch,arms=1 2,week=12);

%let _week26=At any time post-baseline for OASIS 3, the event onset is up to day 182 (inclusive) for EZN 120 mg (week 1-26) and Placebo (week 1-26).;
%_m_rd(indat=adlb_switch,arms=4 5,week=26);

%let _week26=;
%_m_rd(indat=adlb_switch,arms=6 7,week=52);



%endprog();