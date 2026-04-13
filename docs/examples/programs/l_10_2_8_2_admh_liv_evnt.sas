/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_8_2_admh_liv_evnt);
/*
 * Purpose          : Medical history of Interest - Liver Event
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 21NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_8_2_admh_liv_evnt.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/

%m_create_ads_view(adsDomain = admh, outDat = admhall)
%extend_data(indat = admhall, outdat = admh)

*************************< creating listing dates  *****************************;

DATA admhall_1;
    SET admh;
    WHERE MHCAT = 'LIVER DISEASE';
RUN;

%m_create_dtl(inputds=admhall_1, varname= MHSTDTL);
%m_create_dtl(inputds=admhall_1, varname= MHENDTL);

************************< creating listing variable  *****************************;

DATA admh_final;
   SET admhall_1;
    where &saf_cond;
       LABEL   MHTERM = 'Medical History Finding'
               MHSTDTL = 'Start Date of Medical History Finding'
               MHENDTL = 'End Date of Medical History Finding'
               MHENRTPT = 'Ongoing at informed consent'
               TRT01AN     = 'Actual Treatment Group';
RUN;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%MTITLE;

%datalist(
    data     = admh_final
  , page     = &treat_var.
  , by       = SASR
  , var      = MHTERM MHENRTPT MHSTDTL MHENDTL
  , optimal  = y
  , split    =
  , layout   = Standard
  , bylen    = 10
  , hc_align = CENTER
  , hn_align = CENTER
);

%endprog();