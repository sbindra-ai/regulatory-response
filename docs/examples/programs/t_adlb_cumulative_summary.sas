/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
%iniprog(name = t_adlb_cumulative_summary)
;
/*
 * Purpose          : Number of subjects by cumulative hepatic safety laboratory parameter category
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gdcpl (Derek Li) / date: 19OCT2023
 * Reference prog   :
 ******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 08DEC2023
 * Reason           : # Simplify code (use &extend_rule_disp_12_ezn_52_a_afl.,...)
 *                    # Update derivation of "AST or ALT"
 *                    # Update header
 *                    # Use &lb_avisit_selection.
 *                    # Use %m_switcher_avisit2
 *                    # Update deletion of rows with only zeros
 *                    # Use &post_baseline_cond.
 ******************************************************************************/
/* Changed by       : gdcpl (Derek Li) / date: 14FEB2024
 * Reason           : use &extend_rule_disp_12_ezn_52_anofl. to include UNS visit
 ******************************************************************************/
/* Changed by       : ereiu (Katharina Meier) / date: 15FEB2024
 * Reason           : Footnote update
 ******************************************************************************/
/* Changed by       : gdcpl (Derek Li) / date: 27MAR2024
 * Reason           : remove post-baseline relate footnotes
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
  , extend_rule = &extend_rule_disp_12_ezn_52_anofl.
)
;

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , subj_var    = USUBJID
  , var         = &extend_var_disp_12_ezn_52_a.
  , extend_rule = &extend_rule_disp_12_ezn_52_a1.
)
;

* Prepare data;
%m_switcher_avisit2(
    indat  = adlb_ext
  , trtvar = &mosto_param_class.
  , byvar  = paramcd
)
;

DATA adlb_switch;
    SET adlb_ext(where=(paramcd ne 'GGT'));

    *%m_switcher_avisit();
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
    IF avisitn = 5 THEN DO;
        avisit = "Baseline";
        avisitn_new = 1;
    END;
RUN;

* Calculate frequencies;
%overview_tab(
    data      = adlb_tab
  , data_n    = adsl_ext
  , by        = avisitn_new _ord avisit param_label
  , order     = avisitn_new _ord
  , groups    = 'not missing(aval)'    *     'n'
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
  , outdat    = tmp
  , maxlen    = 30
  , split     = '/#*'
  , hsplit    = '#'
)
;

* Select category acc. to SAP 4.4.6.4;
DATA tmp;
    SET tmp;
    IF _order_ = 1 THEN _name_ = strip(_name_);
    IF _ord NE 1 THEN CALL missing(avisit);
    /*
    * Delete rows with only zeros;
    ARRAY Acol $ _col_01 _col_02 _col_03;
    ARRAY An   $     _01     _02     _03 ;
    DO OVER Acol;
        An = strip(scan(_col_01,1,"("));
    END;
    IF _01 = "0" AND _02 = "0" AND _03 = "0"  THEN DELETE;
    */
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
    IF missing(_ord) AND missing(param_label) THEN DELETE;
    IF avisitn_new=2 AND missing(param_label) THEN DELETE;
RUN;

DATA tmpinp;
    SET tmpinp;
    IF keyword = "FREELINE" THEN value="param_label";
    IF keyword = "TOGETHER" THEN value="param_label";
RUN;

* Output;
%set_titles_footnotes(
    tit1 = "Table: Number of subjects by cumulative hepatic safety laboratory parameter category &saf_label."
  , ftn1 = "n = number of subjects with parameter assessment done at respective time point."
  , ftn5 = "At any time post-baseline for OASIS 3, the event onset is up to day 182 (inclusive) for EZN 120 mg (week 1-26)."
  , ftn6 = "Unscheduled visits were included in the analysis. ULN = Upper Limit of Normal."
  , ftn7 = "AST = Aspartate Aminotransferase, ALT = Alanine Transferase, ALP = Alkaline Phosphatase, INR = International Normalized Ratio."
  , ftn8 = 'INR is only available for OASIS 1-3.'
)
;
/*
, ftn2 = "At any time post-baseline is defined for EZN 120 mg (week 1-12) and Placebo (week 1-12) as following: All measurements taken at or after the date of first study drug intake are considered with the following exceptions: For OASIS 1-2 measurements during"
, ftn3 = "<cont> the open-label phase are excluded. For OASIS 3 measurements after the date of first study drug intake + 83 days are excluded. For SWITCH-1, all measurements up to and including the last observation are included."
, ftn4 = "For EZN 120 mg (week 1-52), at any time post-baseline is defined as all measurements taken at or after the first study drug intake of elinzanetant until the last observation."
*/
%mosto_param_from_dat(data = tmpinp, var = g_all)
;
%datalist(&g_all)
;

%endprog()
;
