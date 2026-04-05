/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
%iniprog(name = tf_adlb_liver_cholestatic)
;
/*
 * Purpose          : Cholestatic Drug-induced Liver injury screening plot
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : ereiu (Katharina Meier) / date: 04MAR2024
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : erjli (Yosia Hadisusanto) / date: 05MAR2024
 * Reason           : Remove parentheses
 ******************************************************************************/
/* Changed by       : gdcpl (Derek Li) / date: 22MAY2024
 * Reason           : change to color
 ******************************************************************************/
/* Changed by       : eqczz (Petri Pulkkinen) / date: 28MAY2024
 * Reason           : Select first assessment of maximum value
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
  , where     = paramcd in ('BILITOSP','ALKPHOSP') and &post_baseline_cond.
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
    *%m_switcher_avisit();
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
DATA adlb_final;
    MERGE adlb_trans    (IN = a DROP=_:)
          adlb_trans_adt(IN = b DROP=_:);
    BY &by_vars. ;
    IF a;
    IF nmiss(bilitosp, alkphosp) = 0;

    * A potential cholestatic drug-induced liver injury case (red circled) was defined as having a maximum post-baseline total bilirubin equal to or exceeding 2 x ULN
      within 30 days after post-baseline ALP became equal to or exceeding 2 x ULN.;
    IF (alkphosp >= 2) AND (bilitosp >= 2 AND dt_alkphosp <= dt_bilitosp < dt_alkphosp + 30) THEN flag=1;
RUN;

*< Table;
%set_titles_footnotes(
    tit1 = "Table: Number of subjects with potential Cholestatic DILI by integrated analysis treatment group &saf_label."
  , ftn1 = "This table is generated using maximum liver test abnormalities in the post-baseline period. At any time post-baseline for OASIS 3, the event onset is up to day 182 (inclusive) for EZN 120 mg (week 1-26)."
  , ftn2 = "N = number of participants in integrated analysis treatment group, n = number of participants meeting criteria."
  , ftn3 = "Unscheduled visits were included in the analysis."
  , ftn4 = "ALP = Alkaline Phosphatase, DILI = Drug-Induced Liver Injury, ULN = Upper Limit of Normal."
)
;

DATA adlb_final;
    SET adlb_final;
    FORMAT &mosto_param_class. _trtgrp_split.;
RUN;

%overview_tab(
    data      = adlb_final
  , data_n    = adsl_ext
  , total     = no
  , groups    = 'alkphosp>=2 and bilitosp>=2' * 'Total bilirubin >= 2xULN and ALP >= 2xULN (right upper)'
                'alkphosp< 2 and bilitosp>=2' * "Total bilirubin >= 2xULN and ALP < 2xULN (left upper)"
                'alkphosp>=2 and bilitosp< 2' * "Total bilirubin < 2xULN and ALP >= 2xULN (right lower)"
  , groupstxt = Quadrant
  , split     = '/#*'
  , hsplit    = '/#*'
  , outdat    = tmp
)
;

data tmpinp;
    set tmpinp;
    if keyword='NCOLUMN1' then value='_col_01 _col_02 _col_03  _col_05 ';
    if keyword='VAR' then value='_col_01 _col_02 _col_03  _col_05 ';
RUN;

%mosto_param_from_dat(data = tmpinp, var = config);
%datalist(&config)

*<For figures;

DATA adlb_final;
    SET adlb_final;
    FORMAT &mosto_param_class. _trtgrp.;
RUN;
* Create annotation dataset for flag=1 records;
%sganno;
%sganno_help(sgoval);

DATA anno;
    SET adlb_final(WHERE=(flag=1));
    %sgoval(
        x1         = alkphosp
      , y1         = bilitosp
      , height     = 10
      , width      = 10
      , display    = 'outline'
      , drawspace  = 'DATAVALUE'
      , HEIGHTUNIT = "PIXEL"
      , LAYER      = 'FRONT'
      , LINECOLOR  = "red"
      , WIDTHUNIT  = 'PIXEL'
    )
    ;
RUN;

%LET anno_help = %str(  BORDER='FALSE',      DRAWSPACE="DATAVALUE", FILLCOLOR="black",   LAYER="FRONT",       TEXTCOLOR="black"
                      , TEXTFONT="arial",    TEXTSIZE=2,            TEXTSTYLE="NORMAL",  TEXTWEIGHT="NORMAL", WIDTH=100,            WIDTHUNIT='PERCENT'
                      , X1SPACE='WALLPERCENT', XAXIS='X',             Y1SPACE='WALLPERCENT', YAXIS='Y',           RESET="ALL");
%LET anno_help = %SYSFUNC(compbl(&anno_help.));

DATA anno_text;
    %SGTEXT(
        LABEL   = ' '
      , ANCHOR  = 'TOPLEFT'
      , JUSTIFY = "LEFT"
      , X1      = 1
      , y1      = 100
      , &anno_help.
    )
    ;
RUN;

DATA anno;
    SET anno
        anno_text;
RUN;

* Select data;
DATA ezn_pla_1_12;
    SET adlb_final(WHERE = (&mosto_param_class. IN (1 2)));
RUN;* EZN / PLA week 1-12;
DATA all_ezn_1_26;
    SET adlb_final(WHERE = (&mosto_param_class. IN (4 5)));
RUN;* All EZN week 1-26;
DATA all_ezn_1_52;
    SET adlb_final(WHERE = (&mosto_param_class. IN (6 7)));
RUN;* All EZN week 1-52;

*< Plot;

%gral_style(
    instyle    = presentation
  , outstyle   = report2
  , GraphData1 = markersymbol="Triangle" # contrastcolor=blue
  , GraphData2 = markersymbol="Plus" # contrastcolor=orange
)
;
%MACRO _plot(
       _data    =
     , _trt_grp =
     , _suffix  =
);
    TITLE;
    FOOTNOTE;
    %set_titles_footnotes(tit1 = "Figure: Cholestatic drug-induced liver injury screening plot by &_trt_grp. &saf_label.")
    ;

    FOOTNOTE1 "Each data point represents a participant plotted by their maximum ALP versus their maximum total bilirubin values in the post-baseline period.";
    FOOTNOTE2 "A potential cholestatic drug-induced liver injury case (red circled) was defined as having a maximum post-baseline total bilirubin equal to";
    FOOTNOTE3 "<cont>or exceeding 2 x ULN within 30 days after post-baseline ALP became equal to or exceeding 2 x ULN.";
    %IF %scan(&_data.,-1,_)=26 %THEN %DO;
        FOOTNOTE4 "For OASIS 3, the event onset is up to day 182 (inclusive) for EZN 120 mg (week 1-26) and Placebo (week 1-26).";
        FOOTNOTE5 "Unscheduled visits were included in the analysis.";
        FOOTNOTE6 "ALP =alkaline phosphatase, ULN=upper limit of normal.";
        FOOTNOTE8 "&idfoot";
    %END;
    %ELSE %DO;
        FOOTNOTE4 "Unscheduled visits were included in the analysis.";
        FOOTNOTE5 "ALP =alkaline phosphatase, ULN=upper limit of normal.";
        FOOTNOTE7 "&idfoot";
    %END;

    %ScatterPlot(
        data          = &_data.
      , xvar          = alkphosp
      , yvar          = bilitosp
      , class         = &mosto_param_class.
      , annodata      = ANNO
      , title_ny      = no
      , legendtitle   =
      , style_options = GraphReference_LineStyle=2
      , outdat        = tmp
      , xtype         = LOG
      , xrefline      = 2
      , xlabel        = 'Maximum post-baseline ALP (xULN)'
      , ytype         = LOG
      , yrefline      = 2
      , ylabel        = 'Maximum post-baseline bilirubin (xULN)'
      , filename      = &prog._&_suffix.
      , style         = report2
    )
    ;

    DATA tmpinp;
        SET tmpinp;
        /* Removing index option because it's leading to an inexplicable GTL warning */
        IF object = 'regression' AND attribute = 'index' THEN DELETE;
    RUN;

    %gral_from_dat(data = tmp)

%MEND _plot;
%_plot(
    _data    = ezn_pla_1_12
  , _trt_grp = EZN 120 mg (week 1-12) and Placebo (week 1-12)
  , _suffix  = ezn_pla
)
;* PLA (week 1-12)/ EZN (week 1-12);
%_plot(_data = all_ezn_1_26, _trt_grp = &lbl_ezn_pla_w26., _suffix = ezn_pla1)
;* PLA (week 1-26)/ EZN (week 1-26);
%_plot(_data = all_ezn_1_52, _trt_grp = &lbl_ezn_pla_w52., _suffix = ezn_pla2)
;* PLA (week 1-52)/ EZN (week 1-52);

%endprog()
;
