/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_8_2_adfapr_crv_cyt);
/*
 * Purpose          : Cervical Cytology
 * Programming Spec : 
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4     
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 21NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_8_2_adfapr_crv_cyt.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/

%m_create_ads_view(adsDomain = adfapr, outDat = adfaprall)
%m_create_ads_view(adsDomain = adpr, outDat = adprall)

%extend_data(indat = adfaprall, outdat = adfapr)
%extend_data(indat = adprall, outdat = adpr)

***********************< creating listing dates  ***************************;

DATA adfaprall_1;
    SET adfapr;
    WHERE PARCAT1 ='CERVICAL CYTOLOGY';
RUN;

DATA adprall_1;
    SET adpr;
    WHERE PRCAT = 'CERVICAL CYTOLOGY';
RUN;

%m_create_dtl(inputds=adfaprall_1, varname= FADTL);
%m_create_dtl(inputds=adprall_1, varname= PRSTDTL);

************************< creating listing variable  **********************;

PROC SQL ;
    CREATE TABLE crv_cyt AS
    SELECT coalesce (x.SASR,y.SASR) AS SASR  'Subject Identifier/ Age/ Sex/ Race',
    coalesce (x.ASTDT,y.ADT) AS ASTDT format date9. 'Date',
    coalesce (x.AVISITN,y.AVISITN) AS AVISITN format z_avisit. 'Visit',
    coalesce (x.TRT01AN,y.TRT01AN) AS TRT01AN format Z_TRT. 'Actual Treatment Group',
    coalesce (x.prstat, y.fastat) AS stat,
    coalesce ( x.prreasnd, y.fareasnd) AS reasnd,x.PRSTDTL,
    CASE WHEN y.AVALC = 'Y' THEN 'Normal, clinically significant'
       WHEN y.AVALC = 'N' THEN 'Abnormal, clinically insignificant '
       WHEN y.AVALC = ' ' THEN ' '
       END AS new_aval 'Main result'
          FROM adprall_1 AS x FULL JOIN adfaprall_1 AS y
          ON x.PRLNKID = y.FALNKID;
QUIT;

DATA crv_cyt_final;
    SET crv_cyt;
    DOC = put(ASTDT, date9.);
    IF new_aval = 'Normal, clinically significant' THEN sam_obt = 'Yes';
    ELSE IF new_aval ='Abnormal, clinically insignificant' THEN sam_obt = 'Yes';
    ELSE IF stat = 'NOT DONE' THEN sam_obt = 'No';
    LABEL sam_obt = 'Sample obtained' ;
    LABEL AVISITN = 'Visit';
    LABEL PRSTDTL = 'Date';
    LABEL reasnd = 'Reason no sample obtained';
RUN;

PROC SORT DATA =crv_cyt_final ;
    BY SASR AVISITN ;
RUN;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%MTITLE;

%datalist(
    data     = crv_cyt_final
  , page     = &treat_var.
  , by       = SASR
  , var      = AVISITN PRSTDTL sam_obt reasnd new_aval
  , optimal  = Y
  , maxlen   = 50
  , space    = 5
  , split    = '/*'
  , hsplit   = #
  , layout   = Standard
  , bylen    = 22
  , hc_align = CENTER
  , hn_align = CENTER
);

%endprog();
