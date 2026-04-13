/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_6_2_adds_info_const);
/*
 * Purpose          : Clinical laboratory data: Subjects who signed Pharmacogenetics informed consent
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 17OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_6_2_adds_info_const.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/

%m_create_ads_view(adsDomain = adds, outDat = addsall)

%extend_data(indat = addsall, outdat = adds)

**********************<  creating listing dates  *****************************;

DATA addsall_1;
    SET adds;
    WHERE DSTERM = 'Informed consent for pharmacogenetic research'
          and &fas_cond;
RUN;

%m_create_dtl(inputds=addsall_1, varname= DSSTDTL);

************************<  creating listing variable  ************************;

DATA ds_final;
    SET addsall_1;
    IF DSDECOD = 'INFORMED CONSENT OBTAINED' THEN inf_con_sign= 'YES';
    LABEL inf_con_sign = 'Pharmacogenetics informed consent signed'
          DSSTDTL = 'Signature Date'
           &treat_var_listings_part. = 'Planned Treatment Group';
RUN;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%MTITLE;

%datalist(
    data   = ds_final
  , page   = &treat_var_listings_part.
  , by     = SASR
  , var    = inf_con_sign DSSTDTL
  , maxlen = 30
  , bylen  = 30
)

****************************************************;
*<clean up;
****************************************************;
%endprog;

