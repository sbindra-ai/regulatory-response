/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_3_8_adpr_crv_ct_frq);
/*
 * Purpose          : Number of subjects with cervical cytology results (SAF)
 * Programming Spec :
 * Validation Level : 2 - Independent Programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : epjgw (Roland Meizis) / date: 29NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/t_8_3_8_adpr_crv_ct_frq.sas (egavb (Reema S Pawar) / date: 14JUN2023)
 ******************************************************************************/

%load_ads_dat(
    adpr_view
  , adsDomain = adpr
  , where     = PRCAT = "CERVICAL CYTOLOGY" AND AVISITN NE 900000
  , adslWhere = &saf_cond
  , adslVars  = &treat_var
);

%load_ads_dat(
    adfapr_view
  , adsDomain = adfapr
  , where     = PARCAT1 = "CERVICAL CYTOLOGY"
                AND ANL01FL = 'Y'
                AND AVISITN NE 900000
  , adslWhere = &saf_cond
  , adslVars  = &treat_var
);

%extend_data(indat = adpr_view, outdat = adpr)
%extend_data(indat = adfapr_view, outdat = adfapr)

********************* preparing data for analysis ******************;

/* Screening visit will be shown as baseline */
DATA adpr1;
     SET adpr;
     IF AVISITN = 0 THEN AVISITN =5;
RUN;


PROC SQL ;
    CREATE TABLE final AS
       SELECT adpr.&subj_var.,
              adpr.AVISITN,
              adpr.&treat_var.,
              adpr.PROCCUR label='Cervical cytology sample obtained' format=$x_ny.,
              adpr.PRSTAT,
              adpr.PRREASOC,
              input(PRREASND, _crv_cty_n.)  as NO_REASON 'Of these: Reason' format=_crv_cty.,
              adfapr.AVALC,
              input(AVALC ,_crv_cty_rstn. ) as YES_MAINRESULT 'Of these: main result' format= _crv_cty_rst.,
              adfapr.PARAMCD
       FROM adpr1 AS adpr
       LEFT JOIN adfapr
       ON adpr.PRLNKID = adfapr.FALNKID
       ORDER BY USUBJID;
QUIT;

***************************************;

%freq_tab(
    data        = final
  , data_n      = final
  , var         = PROCCUR*NO_REASON PROCCUR*YES_MAINRESULT
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

DATA one;
    SET one;

    if _var_ = "PROCCUR NO_REASON" then do;
        if proccur="Y" then delete;
    end;
    else if _var_ = "PROCCUR YES_MAINRESULT" then do;
        if proccur="N" or missing(proccur) then delete;
    end;

    _varl_ = tranwrd(_varl_, "- of these: ", "            "); /* Remove the "- of these:" which is automatically created because we are using subvariables of the form var=var1*var2 */
RUN;

***************************************;

%MTITLE;

%mosto_param_from_dat(data = ONEINP, var = config)
%datalist(&config.)

/* Use  at the end of each study program */
%endprog ;