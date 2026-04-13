/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_8_2_adpr_fapr_mamo);
/*
 * Purpose          : Mammogram
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 17OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_8_2_adpr_fapr_mamo.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/

%m_create_ads_view(adsDomain = adpr, outDat = adprall)
%m_create_ads_view(adsDomain = adfapr, outDat = adfaprall)

%extend_data(indat = adprall, outdat = adpr)
%extend_data(indat = adfaprall, outdat = adfapr)

***************************< creating listing dates  *********************************;

DATA adprall_1;
    SET adpr;
    WHERE PRTRT = 'MAMMOGRAM'
           and &saf_cond;
RUN;

DATA adfaprall_1;
    SET adfapr;
    WHERE PARCAT1 ='MAMMOGRAPHY'
           and &saf_cond;
RUN;

%m_create_dtl(inputds=adprall_1, varname= PRSTDTL);

************************< creating listing variable ***********************************;

PROC SQL;
   CREATE TABLE mamo AS
       SELECT coalesce (x.SASR,y.SASR) AS SASR  'Subject Identifier/ Age/ Sex/ Race',
       coalesce (x.ASTDT,y.ADT) AS ASTDT format date9. ,
       coalesce (x.AVISITN,y.AVISITN) AS AVISITN format z_avisit. 'Visit',
       coalesce (x.TRT01AN,y.TRT01AN) AS TRT01AN format Z_TRT. 'Actual Treatment Group',
       x.PROCCUR format $x_ny. 'Mammogram performed',
       propcase(x.PRREASND) AS rsn_nd 'Reason not done',x.PRSTDTL 'Date',
       propcase(y.AVALC) AS mn_rst 'Main result'
              FROM adprall_1 AS x FULL JOIN adfaprall_1 AS y
              ON x.PRLNKID = y.FALNKID;
QUIT;

PROC SORT DATA = mamo OUT = mamo_f ;
    BY &treat_var. SASR  ASTDT;
RUN;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;


%MTITLE;

%datalist(
    data     = mamo_f
  , page     = &treat_var.
  , by       = SASR AVISITN
  , var      = PRSTDTL PROCCUR rsn_nd mn_rst
  , order    =
  , optimal  = Y
  , maxlen   = 40
  , space    = 5
  , split    = '/*'
  , hsplit   = #
  , layout   = Standard
  , bylen    = 22
  , hc_align = CENTER
  , hn_align = CENTER
);

%endprog();
