/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_8_2_adpr_adfapr_liv);
/*
 * Purpose          : Procedure(s) - Liver Event
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 17OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_8_2_adpr_adfapr_liv.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/

%m_create_ads_view(adsDomain = adfapr, outDat = adfaprall)
%m_create_ads_view(adsDomain = adpr, outDat = adprall)

%extend_data(indat = adfaprall, outdat = adfapr)
%extend_data(indat = adprall, outdat = adpr)

***************************<  creating listing dates  *****************************;
DATA adfaprall_1;
    SET adfapr;
    WHERE PARCAT1 ='Liver event'
           and &saf_cond;
RUN;

DATA adprall_1;
    SET adpr;
    WHERE PRCAT ='LIVER EVENT'
           and &saf_cond;
RUN;

%m_create_dtl(inputds=adfaprall_1, varname= FADTL);
%m_create_dtl(inputds=adprall_1, varname= PRSTDTL);

************************< creating listing variable ******************************;

PROC SQL;
   CREATE TABLE adpr_liv AS
       SELECT coalesce (x.SASR,y.SASR) AS SASR  'Subject Identifier/ Age/ Sex/ Race',
       coalesce (x.TRT01AN,y.TRT01AN) AS TRT01AN format Z_TRT. 'Actual Treatment Group',
       x.PROCCUR format $x_ny. 'Procedure Performed',x.PRREASND 'Reason Not Done',
       x.PRPRESP format $x_ny.,x.PRSTDTL  'Date Of Procedure',x.PRTRT 'Procedure Name',
       y.FATEST ,y.AVALC 'Procedure Findings'
              FROM adprall_1 AS x FULL JOIN adfaprall_1 AS y
              ON x.PRLNKID = y.FALNKID;
QUIT;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%MTITLE;

%datalist(
    data     = adpr_liv
  , page     = &treat_var.
  , by       = SASR
  , var      = PRTRT PROCCUR PRSTDTL AVALC PRREASND
  , optimal  = y
  , split    =
  , layout   = Standard
  , bylen    = 16
  , hc_align = CENTER
  , hn_align = CENTER
);

%endprog();