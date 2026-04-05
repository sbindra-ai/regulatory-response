
/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adqs_clo_ir26);
/*
 * Purpose          : Number of subjects meeting close liver observation and assessment by liver safety monitoring board (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : evmqe (Endri Elnadav) / date: 30MAY2024
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 05SEP2024
 * Reason           : Update ftn9 to make unique with t_adqs_clo, t_adqs_clo_ir52 wording
 ******************************************************************************/

%LET mosto_param_class = %scan(&extend_var_disp_26_nt_a., 1, '@');

%LET l_miss = %sysfunc(getoption(missing));
OPTIONS MISSING='';


%load_ads_dat(adsl, adsDomain = adsl, where = &saf_cond. AND studyid NOT IN ('21686'))
%extend_data(
    indat       = adsl
  , outdat      = adsl_ext
  , var         = &extend_var_disp_26_nt_a.
  , extend_rule = &extend_rule_disp_26_nt_a.
)

DATA adqs;
    SET sp.qs(WHERE=(qscat    = "CLOSE LIVER OBSERVATION CASE REVIEW (V1.0)"
                 AND qstestcd = "CLB105"));
         IF qsstresc = "N" THEN critfln = 1; %** _ynm.1 [No];
    ELSE IF qsstresc = "Y" THEN critfln = 2; %** _ynm.2 [Yes];
    ELSE                        critfln = 3; %** _ynm.3 [Missing];

    FORMAT critfln _ynm.;
    LABEL  qstestcd = ' ';
RUN;

%mergeDat(
    baseDat           = adqs
  , keyDat            = adsl(KEEP=&subj_var. ph1sdt ph1edt ph2sdt ph2edt trt01an trt02an trtsdt trtedt dthdt)
  , by                = &subj_var.
  , dropNonKeyDatRecs = YES
)

DATA adqs_aphase;
    SET adqs;
    ATTRIB aphase LABEL = "Phase" LENGTH=$200;
    astdt = input(qsdtc, yymmdd10.);
    astdy = qsdy;
    FORMAT astdt date9.;

    IF n(astdt,ph1sdt,ph1edt) = 3 THEN DO;
            IF ph1sdt <= astdt <= ph2sdt                                        THEN aphase = "Week 1-12";
    END;
    ELSE IF missing(ph1edt) AND n(astdt,ph1sdt)=2 AND astdt > ph1sdt            THEN aphase = "Week 1-12";
    ELSE IF astdt EQ . AND ph2sdt EQ .                                          THEN aphase = "Week 1-12";

    IF studyid NE '21810' THEN DO;
    IF n(astdt,ph2sdt) = 2  AND astdt > ph2sdt                                  THEN aphase = "Week 13-52";
        ELSE IF astdt EQ . AND ph2sdt NE .                                      THEN aphase = "Week 13-52";
    END;
    ELSE DO;/* For OASIS 3*/
        IF  n(astdt,ph2sdt) = 2 AND astdt >  ph2sdt  AND astdt <= ph1sdt + 182 - 1                               THEN aphase = "Week 13-52";
        IF  n(astdt,ph1edt) = 2 AND astdt >  ph1edt  AND astdt <= ph1sdt + 182 - 1 AND MISSING(ph2sdt)           THEN aphase = "Week 13-52";
    END;

RUN;

DATA ads.adqs_aphase;
    SET adqs_aphase;

RUN;

%extend_data(
    indat       = adqs_aphase
  , outdat      = adqs_ext
  , var         = &extend_var_disp_26_nt_a.
  , extend_rule = &extend_rule_disp_26_nt_a_ae.
)

PROC SORT DATA = adqs_ext OUT = adqs_ext_max (KEEP = usubjid astdt RENAME= (astdt = astdt_max));
  BY &subj_var. astdt;
RUN;
DATA adqs_ext_max;
    SET adqs_ext_max;
    BY &subj_var.;
    IF LAST.&subj_var.;
RUN;


PROC SORT DATA = adqs_ext OUT = adqs_ext_max (KEEP = usubjid astdt RENAME= (astdt = astdt_max));
  BY &subj_var. astdt;
RUN;
DATA adqs_ext_max;
    SET adqs_ext_max;
    BY &subj_var.;
    IF LAST.&subj_var.;
RUN;


%m_add_time_window_lab(indat = adsl_ext, outdat = adsl_ext);
Proc sort;  BY &subj_var.; RUN;
DATA adsl_ext;
      MERGE adsl_ext
            adqs_ext_max;
      BY &subj_var.;
      IF enddt < astdt_max THEN enddt = astdt_max;
RUN;


DATA adqs22;
    SET adqs_ext;
    critfln = 0;
RUN;
%freq_tab(
    data              = adqs22
  , data_n            = adsl_ext
  , var               = critfln
  , subject           = &subj_var.
  , by                = qstestcd
  , data_n_ignore     = qstestcd
  , total             = NO
  , class             = &mosto_param_class.
  , basepct           = N_CLASS
  , hlabel            = Yes
  , misstext          = Missing
  , outdat            = _stat0
  , harmonized_outdat = N
  , missing           = NO
  , completeclass     = DATA
  , label             = No
)

%m_inc_100_patyears(
    indat       = adqs22
  , indat_adsl  = adsl_ext
  , censordt    = enddt
  , startdt     = startdt
  , var         = qstestcd
  , triggercond = critfln = 0
  , outdat      = _stat0_py
)

%freq_tab(
    data              = adqs_ext
  , data_n            = adsl_ext
  , var               = critfln
  , subject           = &subj_var.
  , by                = qstestcd
  , data_n_ignore     = qstestcd
  , total             = NO
  , class             = &mosto_param_class.
  , hlabel            = Yes
  , misstext          = Missing
  , outdat            = _stat1
  , harmonized_outdat = N
  , missing           = Yes
  , complete          = ALL
  , completeclass     = DATA
  , print_empty       = Yes
  , order_var         = critfln = "No" "Yes" "Missing"
  , label             = No
)

%m_inc_100_patyears(
    indat       = adqs_ext
  , indat_adsl  = adsl_ext
  , censordt    = enddt
  , startdt     = startdt
  , var         = qstestcd
  , triggercond = critfln = 2
  , outdat      = _stat1_py
  , debug = YES
)

DATA _stat0__1;
    SET _stat0;
    ARRAY cptog_array(*) _cptog1-_cptog4;
    DO i = 1 TO dim(cptog_array);
        ** Remove (100%);
        cptog_array(i) = prxchange("s/\s+\(100%\)//", -1, cptog_array(i));
        ** Add parentheses around N=xxx to get the same N_COLUMN like _stat1 for Big N;
        cptog_array(i) = prxchange("s/(N=\d+)/($1)/", -1, cptog_array(i));
    END;

RUN;

DATA _stat0;
    LENGTH Paramcd_n $100;
    SET _stat0__1 ;
    Paramcd_n = "Case Met Close Liver Observation";
    _ord_   = 0;
    _newvar = 0 ;
    _nr2_   = 1;
    _varl_  = 'n';
RUN;

DATA _stat1 ;
    LENGTH paramcd_n $100;
    SET _stat1;
    IF _varl_ = 'n' THEN DELETE;
    paramcd_n = "Case Met Liver Injury Criteria";
RUN;

DATA _stat1 ;
    SET _stat0 _stat1;
RUN;

%* get EAIR data;
PROC SQL;
   CREATE TABLE _stat9_all AS
                    SELECT 'n'   AS _varl_ , eair_1, eair_2   FROM _stat0_py WHERE NOT MISSING(qstestcd)
   OUTER UNION CORR SELECT 'Yes' AS _varl_ , eair_1, eair_2   FROM _stat1_py WHERE NOT MISSING(qstestcd);
QUIT;

PROC SQL;
  CREATE TABLE _stat2 AS
  SELECT l.*
       , r.eair_1
       , r.eair_2
  FRom           _stat1 as  l
       LEFT JOIN _stat9_all AS r
  ON l._varl_ = r._varl_
  ORDER BY _ord_;
QUIT;

%* Merge the _COL variables with AEIR and saved it in &indat_mosto. dataset;
DATA _stat3;
    SET _stat2;
        n_1 = scan(_cptog1, 1, 'N');  big_n_1 = scan(_cptog1, 2, 'N');
        n_2 = scan(_cptog2, 1, 'N');  big_n_2 = scan(_cptog2, 2, 'N');

        ARRAY vars n_1 n_2 big_n_1 big_n_2;
        DO over vars;
            vars = SUBSTR(vars, 1, LENGTH(vars) - 1);
        END;

        IF NOT MISSING(eair_1) THEN ir_1 = put(eair_1, 8.2); ELSE ir_1 = '~~~~~~~~';
        IF NOT MISSING(eair_2) THEN ir_2 = put(eair_2, 8.2); ELSE ir_2 = '~~~~~~~~';

        _cptog1 = PUT(n_1, $15.) !! "    " !! PUT(ir_1, $15.) !! ' N' !! PUT(big_n_1, $15.)  !! "    #n (%)        IR* (100 person-years)";
        _cptog2 = PUT(n_2, $15.) !! "    " !! PUT(ir_2, $15.) !! ' N' !! PUT(big_n_1, $15.)  !! "    #n (%)        IR* (100 person-years)";

        _cptog1 = TRANSLATE(_cptog1, ' ', '~');
        _cptog2 = TRANSLATE(_cptog2, ' ', '~');
RUN;

DATA _stat3;
    SET _stat2;
        n_1 = scan(_cptog1, 1, 'N');  big_n_1 = scan(_cptog1, 2, 'N'); ir_1 = put(eair_1, 8.2);
        n_2 = scan(_cptog2, 1, 'N');  big_n_2 = scan(_cptog2, 2, 'N'); ir_2 = put(eair_2, 8.2);

        ARRAY vars n_1 n_2 big_n_1 big_n_2;
        DO over vars;
            vars = SUBSTR(vars, 1, LENGTH(vars) - 1);
        END;

        _cptog1 = catt(n_1,"    ",ir_1,' N', big_n_1, "    #n (%)        IR* (100 person-years)");
        _cptog2 = catt(n_2,"    ",ir_2,' N', big_n_2, "    #n (%)        IR* (100 person-years)");
RUN;


DATA _statinp;
    SET _stat1inp;
    IF keyword = 'DATA'     then VALUE = '_stat3';
    IF keyword = 'BY'       THEN value = 'Paramcd_n _widownr _nr2_ _ord_ _newvar _type_ _kind_ _varl_';
    IF keyword = 'ORDER'    THEN value = '_widownr _nr2_ _ord_ _newvar _type_ _kind_';
    IF keyword = 'FREELINE' THEN value = 'Paramcd_n';
    IF keyword = 'TOGETHER' THEN value = 'Paramcd_n';
RUN;

%mosto_param_from_dat(data = _statinp, var = paramcd_n);


%set_titles_footnotes(
    tit1 = "Table: Number of subjects meeting close liver observation and assessment by liver safety monitoring board up to week 26 &saf_label."
  , ftn1 = "n = the number of subjects meeting close liver observation as per Table 10-2 of the protocol."
  , ftn2 = "Percentage for Case Met Close Liver Observation is based on total number of subjects (N), percentage for Cases Met Liver Injury Criteria is based on the total number of Case Met Close Liver Observation (n)."
  , ftn3 = "For OASIS 3, the event onset is up to day 182 (inclusive) for EZN 120 mg (week 1-26) and Placebo (week 1-26)."
  , ftn4 = "Study size and exposure-adjusted IRs are calculated as following: For each study and treatment group, the exposure-adjusted incidence (= number of participants with event / sum of exposure days) is multiplied"
  , ftn5 = "<cont>by the proportion of the study exposure to the total exposure across studies. Results are then added up across all studies for each treatment group."
  , ftn6 = "Where sum of exposure days = sum of time to first event for participants if an event occurred + sum of treatment duration with time after treatment up to end of observation for participants without event."
  , ftn7 = "End of observation is defined as post-baseline as defined in the IA SAP. Results are provided per 100 person-years, where one person-year is defined as 365.25 days."
  , ftn8 = "*IRs are study size adjusted incidence rates according to Crowe et al (2016)."
  , ftn9 = "Close liver observation cases have not been defined in SWITCH-1. Therefore, this study is excluded from this analysis. Unscheduled visits were included in the analysis."
);

%datalist(&paramcd_n.);
OPTION MISSING="&l_miss.";

%endprog()


