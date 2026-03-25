/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adqs_clo);
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
 * Author(s)        : erjli (Yosia Hadisusanto) / date: 04MAR2024
 * Reference prog   : /var/swan/root/bhc/3427080/21810/stat/main01/dev/analysis/pgms/t_8_3_5_8_alb_cyst_nu.sas
 ******************************************************************************/
/* Changed by       : erjli (Yosia Hadisusanto) / date: 27MAR2024
 * Reason           : Add footnote: The table does not include two cases from the placebo arm in OASIS 3 that met the liver injury criteria after week 12.
 ******************************************************************************/
/* Changed by       : eqczz (Petri Pulkkinen) / date: 24MAY2024
 * Reason           : 1) Update definition of analysis phase
 *                    2) Remove reference for 84 days in footnote
 *                    3) Update footnote about placebo CLOs after 12 weeks
 ******************************************************************************/
/* Changed by       : eqczz (Petri Pulkkinen) / date: 30MAY2024
 * Reason           : Returned previous footnote about 2 liver injury cases in
 *                    placebo arm and added footnote about SWITCH-1
 ******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 05SEP2024
 * Reason           : Exclude SWITCH-1
 ******************************************************************************/


%LET mosto_param_class = %scan(&extend_var_disp_12_ezn_52_a, 1, '@');

%load_ads_dat(adsl, adsDomain = adsl, where = &saf_cond. AND studyid NOT IN ('21686'))

%extend_data(
    indat       = adsl
  , outdat      = adsl_ext
  , subj_var    = USUBJID
  , var         = &extend_var_disp_12_ezn_52_a.
  , extend_rule = trt01an in (53)                           # &trt_ezn_12.
                @ trt01an in (9901)                         # &trt_pla_12.
                @ trt01an in (53) OR trt02an IN (53)        # &trt_ezn_52.
                @ trt01an in (53) OR trt02an IN (53)        # &trt_ezn_26.
)

DATA adqs;
    SET sp.qs(WHERE=(qscat    = "CLOSE LIVER OBSERVATION CASE REVIEW (V1.0)"
                 AND qstestcd = "CLB105"
              ));
         IF qsstresc = "N" THEN critfln = 1; %** _ynm.1 [No];
    ELSE IF qsstresc = "Y" THEN critfln = 2; %** _ynm.2 [Yes];
    ELSE                        critfln = 3; %** _ynm.3 [Missing];

    FORMAT critfln _ynm.;
    LABEL  qstestcd = ' ';
RUN;

%mergeDat(
    baseDat           = adqs
  , keyDat            = adsl(KEEP=&subj_var. ph1sdt ph1edt ph2sdt ph2edt trt01an trt02an trtsdt trtedt)
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
        IF  n(astdt,ph2sdt) = 2 AND astdt >  ph2sdt                             THEN aphase = "Week 13-52";
        IF  n(astdt,ph1edt) = 2 AND astdt >  ph1edt  AND MISSING(ph2sdt)        THEN aphase = "Week 13-52";
    END;
RUN;

%LET ezn_pure_cond          = (trt01an in (53));
%LET ezn_switcher_cond      = (trt02an in (53) and aphase = 'Week 13-52');
%LET ezn_pure_cond26        = ((studyid ne '21810' AND trt01an in (53)) OR (studyid eq '21810' AND trt01an in (53) AND . < astdy <= 182));
%LET ezn_switcher_cond26    = (trt02an in (53) and aphase = 'Week 13-52');

%extend_data(
    indat       = adqs_aphase
  , outdat      = adqs_ext
  , var         = &extend_var_disp_12_ezn_52_a.
  , extend_rule = (trt01an in (53)   and aphase = 'Week 1-12') # &trt_ezn_12.
                @ (trt01an in (9901) and aphase = 'Week 1-12') # &trt_pla_12.
                @  &ezn_pure_cond. OR &ezn_switcher_cond.      # &trt_ezn_52.
                @  &ezn_pure_cond26. OR &ezn_switcher_cond26.  # &trt_ezn_26.
)

DATA adqs22;
    SET adqs_ext;
    critfln = 0;
RUN;

%set_titles_footnotes(
    tit1 = "Table: Number of subjects meeting close liver observation and assessment by liver safety monitoring board &saf_label."
  , ftn1 = "n = the number of subjects meeting close liver observation as per Table 10-2 of the protocol."
  , ftn2 = "Percentage for Case Met Close Liver Observation is based on total number of subjects (N), percentage for Cases Met Liver Injury Criteria is based on the total number of Case Met Close Liver Observation (n)."
  , ftn3 = "For OASIS 3, the event onset is up to day 182 (inclusive) for EZN 120 mg (week 1-26)."
  , ftn4 = "Unscheduled visits were included in the analysis."
  , ftn5 = "The table does not include four cases from the placebo arm in OASIS 3 that met the close liver observation criteria after week 12."
  , ftn6 = "The table does not include two cases from the placebo arm in OASIS 3 that met the liver injury criteria after week 12."
  , ftn7 = "Close liver observation cases have not been defined in SWITCH-1. Therefore, this study is excluded from this analysis."
)

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

DATA _statinp;
    SET _stat1inp;
    IF keyword = "BY"       THEN value = "Paramcd_n _widownr _nr2_ _ord_ _newvar _type_ _kind_ _varl_";
    IF keyword = "ORDER"    THEN value = "  _widownr _nr2_ _ord_ _newvar _type_ _kind_";
    IF keyword = 'FREELINE' THEN value = 'Paramcd_n';
    IF keyword = 'TOGETHER' THEN value = 'Paramcd_n';
RUN;

%mosto_param_from_dat(data = _statinp, var = Paramcd_n)

%datalist(&Paramcd_n)

%endprog()


