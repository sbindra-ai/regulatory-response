/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name     = l_10_2_3_adsl_analy_set);
/*
 * Purpose          : Analysis sets
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gniiq (Mayur Parchure) / date: 30OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/l_10_2_3_adsl_analy_set.sas (gniiq (Mayur Parchure) / date: 30OCT2023)
 ******************************************************************************/

%load_ads_dat(
    adsl_view
  , adsDomain = adsl
)

%extend_data(indat = adsl_view, outdat = adsl)

DATA adsl_fin;
    SET adsl;
    LABEL SASR = "Subject Identifier/#Age/ Sex/ Race";
    LABEL SAFFL="Safety#Analysis Set";
    LABEL SAFEXRE1="Reason for Exclusion from#Safety Analysis Set";
    LABEL FASFL="Full#Analysis Set";
    LABEL FASEXRE1="Reason for Exclusion from#Full Analysis Set";
    LABEL SLASFL = "Sleep#Analysis Set";
    LABEL SLAEXRE1 = "Reason for Exclusion from#Sleep Analysis Set";
    LABEL &treat_var. = 'Actual Treatment Group';
RUN;

%MTITLE;

%datalist(
    data            = adsl_fin
  , page            = &treat_var.
  , by              = SASR
  , var             = FASFL FASEXRE1 SAFFL SAFEXRE1 SLASFL SLAEXRE1
  , order           = USUBJID
  , optimal         = N
  , maxlen          = 35
  , hsplit          = "#"
  , bylen           = 25
  , ignore_prespace = yes
)

%endprog()