/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_3_6_adpr_mmo_frq);
/*
 * Purpose          : Number of subjects with overview of collected mammogram results  (SAF)
 * Programming Spec :
 * Validation Level : 2 - Independent Programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : epjgw (Roland Meizis) / date: 04DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/t_8_3_6_adpr_mmo_frq.sas (egavb (Reema S Pawar) / date: 14JUN2023)
 ******************************************************************************/


%load_ads_dat(
    adpr_view
  , adsDomain = adpr
  , where     = PRTRT = "MAMMOGRAM" AND AVISITN <900000
  , adslWhere = &saf_cond
  , adslVars  = &treat_var
);

%load_ads_dat(
    adfapr_view
  , adsDomain = adfapr
  , where     = ANL01FL = "Y" AND PARCAT1 = "MAMMOGRAPHY" AND AVISITN <900000
  , adslWhere = &saf_cond
  , adslVars  = &treat_var
);

%extend_data(indat = adpr_view, outdat = adpr)
%extend_data(indat = adfapr_view, outdat = adfapr)

/* Screening visit will be shown as baseline */
data adpr2;
    set adpr;
    if avisitn = 0 then avisitn = 5;
run;

PROC SQL;
    CREATE TABLE final AS
       SELECT adpr.&subj_var.,
              adpr.AVISITN,
              adpr.&treat_var.,
              adpr.PROCCUR label='Mammogram performed' format=$x_ny.,
              adpr.PRSTAT,
              adpr.PRREASOC,
              PRREASND,
              input(PRREASND,_mamo_rsn_n. ) as NO_REASON label='Of these: Reason' format=_mamo_rs.,
              adfapr.AVALC,
              input(AVALC, _mamo_fnd_n.) as YES_MAINRESULT label='Of these: main result' format=_mamo_fnd.
       FROM adpr2 as adpr
       LEFT JOIN adfapr
       ON adpr.PRLNKID = adfapr.FALNKID
       ORDER BY USUBJID;
QUIT;

***************************************;

%MTITLE;

/* Strategy: Create all possible combinations of proccur and no_reasons, yes_mainresult then delete unnecessary lines */
%freq_tab(
    data        = final
  , data_n      = final
  , var         = PROCCUR*NO_REASON PROCCUR*YES_MAINRESULT
  , subject     = &subj_var.
  , by          = AVISITN
  , total       = NO
  , class       = &treat_var.
  , basepct     = N_MAIN
  , levlabel    = YES
  , header_bign = NO
  , misstext    =
  , outdat      = one
  , missing     = NO
  , complete    = ALL
  , freeline    = AVISITN
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


%mosto_param_from_dat(data = ONEINP, var = config)
%datalist(&config.)


/* Use  at the end of each study program */
%endprog;