/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_3_7_gyn_ult_frq);
/*
 * Purpose          : Number of subjects with gynecological ultrasound performed (SAF)
 * Programming Spec :
 * Validation Level : 2 - Independent Programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : epjgw (Roland Meizis) / date: 04JAN2024
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/t_8_3_7_gyn_ult_frq.sas (egavb (Reema S Pawar) / date: 15JUN2023)
 ******************************************************************************/

%load_ads_dat(
    adpr_view
  , adsDomain = adpr
  , where     = PRCAT = "GYNECOLOGICAL EXAMINATION"
                AND AVISITN ^= 900000
  , adslWhere = &saf_cond
  , adslVars  = &treat_var
);

%load_ads_dat(
    adfapr_view
  , adsDomain = adfapr
  , where     = ANL01FL EQ "Y"
                AND PARCAT1 = "ULTRASOUND"
                AND AVISITN ^= 900000
  , adslWhere = &saf_cond
  , adslVars  = &treat_var
);
%load_ads_dat(adsl_view, adsDomain = adsl, where = &saf_cond)

**************************  %extend_data ***************************;

%extend_data(indat = adsl_view, outdat = adsl)
%extend_data(indat = adpr_view, outdat = pr_final)
%extend_data(indat = adfapr_view, outdat = fapr_final)


******************************ultra sound subjects************************************;

DATA pr_ultra;
    SET pr_final (where=(missing(PRSCAT)));

    FORMAT Proccur $x_ny.  PRREASND1 gyn_rns_nd.;
    PRREASND1 = input(PRREASND,  gyn_rns_nd_n.);
    IF AVISITN = 0 THEN AVISITN = 5;
    KEEP USUBJID &treat_var AVISITN PRTRT PROCCUR PRSTAT PRREASND prreasoc PRSCAT PRCAT PRDECOD  PRREASND1;
RUN;

**************************  Result  *****************;

DATA intrpt ;
     SET fapr_final (where=(PARAMCD IN ('FAINTP'))) ;

     ATTRIB  result_new FORMAT =_ultr_rsl.;
     new_aval =propcase(avalc) ;
     result_new = input(new_aval,_ultr_rsl_n. );
     FORMAT FACLSIG $x_ny.;
     KEEP USUBJID &treat_var AVISITN FAREASND AVALC FAOBJ PARAMCD FACLSIG  result_new  new_aval;
RUN;


******************************  OVARIES and UTERUS ************************************;

DATA ovr_utr;
    SET pr_final (where=(PRSCAT IN( 'ULTRASOUND OVARIES VISUALIZED' 'ULTRASOUND UTERUS')));

    IF AVISITN = 0 THEN AVISITN = 5;
    KEEP USUBJID &treat_var AVISITN PRTRT PROCCUR PRSTAT PRREASND prreasoc PRSCAT PRCAT PRDECOD;
RUN;

PROC SORT DATA = ovr_utr OUT= ovr_utr_sort NODUPKEY;
    BY &treat_var USUBJID  AVISITN PRTRT PRSTAT PRREASND PRSCAT;
RUN;

PROC TRANSPOSE DATA = ovr_utr_sort OUT= ovr_utr_trans (DROP = _NAME_ _LABEL_ );
    ID PRSCAT ;
    VAR PROCCUR;
    BY &treat_var USUBJID AVISITN PRTRT;
    IDLABEL PRSCAT;
RUN;

DATA ovr_utr_f;
    SET ovr_utr_trans;

    ATTRIB gyn_ultrs_perf format=_gyn_ultr_perf. label="Gynecological ultrasound performed";
    IF ULTRASOUND_OVARIES_VISUALIZED = 'Y' AND ULTRASOUND_UTERUS = 'Y' THEN do; gyn_ultrs_perf = 1; output; end;
    if                                         ULTRASOUND_UTERUS = 'Y' then do; gyn_ultrs_perf = 2; output; end;
    if ULTRASOUND_OVARIES_VISUALIZED = 'Y'                             then do; gyn_ultrs_perf = 3; output; end;
RUN;

**************************  Method  *****************;

ODS ESCAPECHAR="^";

DATA ultra_method  ;
     SET fapr_final (where=(paramcd IN ('METHEX')));

     ATTRIB method FORMAT =_method. LABEL= "Method(s) of examination (View of ultrasound)^&super_a" ;
     new_aval =propcase(avalc);
     method = input(new_aval,_methodn. );
     KEEP USUBJID &treat_var AVISITN method;
RUN;

*************************************************;

PROC SORT DATA = pr_ultra;BY &treat_var &subj_var.  AVISITN ;RUN;
PROC SORT DATA = intrpt;BY &treat_var &subj_var.  AVISITN ;RUN;

DATA final;
    MERGE pr_ultra(IN=a) intrpt (IN=b) ;
    BY &treat_var &subj_var. AVISITN ;
    IF a ;
    LABEL PROCCUR = 'Ultrasound performed'
          PRREASND1 = 'Of these: Reason'
          result_new = 'Of these: main result'
          FACLSIG = 'Yes, clinically significant?';
RUN;

%freq_tab(
    data        = final
  , data_n      = adsl
  , var         = PROCCUR*PRREASND1
  , subject     = &subj_var.
  , by          = AVISITN
  , total       = NO
  , class       = &treat_var
  , basepct     = N_MAIN
  , levlabel    = YES
  , header_bign = NO
  , misstext    =
  , outdat      = one
  , missing     = NO
  , complete    = ALL
  , freeline    =
)

%freq_tab(
    data        = final (where=(proccur='Y'))
  , data_n      = adsl
  , var         = result_new*FACLSIG
  , subject     = &subj_var.
  , by          = AVISITN
  , total       = NO
  , class       = &treat_var
  , basepct     = N_MAIN
  , levlabel    = YES
  , header_bign = NO
  , misstext    = Missing /*<#orange If misstext is changed, it also has to be changed below when editing outdat */
  , outdat      = one_b
  , missing     = YES
  , complete    = ALL
  , freeline    =
)

*************************************************;

%freq_tab(
    data        = ovr_utr_f
  , data_n      = adsl
  , var         = gyn_ultrs_perf
  , subject     = &subj_var.
  , by          = AVISITN
  , total       = NO
  , class       = &treat_var
  , header_bign = NO
  , misstext    =
  , outdat      = two
  , missing     = NO
  , complete    = ALL
)


*************************************************;

%freq_tab(
    data        = ultra_method
  , data_n      = adsl
  , var         = method
  , subject     = &subj_var.
  , by          = AVISITN
  , total       = NO
  , class       = &treat_var
  , header_bign = NO
  , misstext    =
  , outdat      = three
  , missing     = NO
  , complete    = ALL
)


*************************************************;

DATA outdat_stack;
    SET one   (in=_one)
        one_b (in=_one_b)
        two   (in=_two)
        three (in=_three);

    if      _one   then ord = 1;
    else if _one_b then ord = 1.5;
    else if _two   then ord = 2;
    else if _three then ord = 3;

    if ord = 1.5 then do;
        /* Delete subcategories for "Yes, clinically significant" if result not "Abnormal" */
        if (_TYPE_ > 2 and (result_new NE 2)) then delete;

        /* Delete lines with Missing, except for main result */
        if index(_varl_, "Missing") and _TYPE_ > 2 then delete;

        /* Move category "Missing" to the end */
        if      _ord_ =  2 then _ord_ = 13.5;
        else if _ord_ = 15 then _ord_ = 26.5;
    end;

    IF ord = 1 and _varl_ = '   n' THEN do;
        _newvar = 0;
        _varl_ = strip(_varl_);
    end;

    /* Remove the "- of these:" which is automatically created because we are using subvariables of the form var=var1*var2 */
    _varl_ = tranwrd(_varl_, "- of these: ", "            ");

    /* Fix indentation of subcategories of "Yes" results */
    if ord = 1 and _var_ = 'RESULT_NEW FACLSIG' then _varl_ = '      ' || _varl_;

    /* Remove unnecessary 'n' lines */
    IF ord = 1 and _var_ = 'RESULT_NEW FACLSIG' AND strip(_varl_) = 'n' THEN DELETE;
    if ord in (1.5, 2, 3) and strip(_varl_) = 'n' then delete;
RUN;

DATA outdat_stackinp;
    SET oneinp;
    IF keyword = 'DATA' THEN value = 'outdat_stack';
    IF keyword = 'FREELINE' THEN value = 'ord ';
    IF keyword = 'BY' THEN value =  ' AVISITN ord _widownr _nr2_ _ord_ _newvar _type_ _kind_ _varl_';
    IF keyword = 'ORDER' THEN value = ' ord _widownr _nr2_ _ord_ _newvar _type_ _kind_ ';
RUN;

*************************************************;

%MTITLE;

%mosto_param_from_dat(data = outdat_stackinp, var = config)
%datalist(&config.)

/* Use %endprog at the end of each study program */
%endprog;