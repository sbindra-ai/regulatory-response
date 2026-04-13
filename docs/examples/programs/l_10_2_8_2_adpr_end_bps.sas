/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_8_2_adpr_end_bps);
/*
 * Purpose          : Endometrial biopsy
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 17OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_8_2_adpr_end_bps.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/

%load_ads_dat(adsl_view , adsDomain = adsl , where =  &saf_cond )
%extend_data(indat = adsl_view, outdat = adsl)

DATA PR;
    SET sp.pr;
     WHERE PRTRT = "Endometrial biopsy";
     KEEP USUBJID VISITNUM VISIT PRTRT PRLNKID PRSTDTC PROCCUR PRSTAT PRREASND;
RUN;

%extend_data(indat = pr, outdat = pr_all)

DATA faPR;
    SET sp.fapr;
     WHERE FACAT IN ( 'ENDOMETRIAL BIOPSY' 'ENDOMETRIAL BIOPSIES') ;
     FADTC = substr (FADTC,1,10 );
     KEEP USUBJID VISITNUM VISIT FALNKID FACAT FATESTCD FADTC FATEST FASCAT FAORRES FAEVALID;
RUN;
%extend_data(indat = fapr, outdat = fapr_all)

*****************************<  creating listing dates  ******************************;

%m_create_dtl(inputds=fapr_all, varname= FADTL);
%m_create_dtl(inputds=pr_all, varname= PRSTDTL);

*****************************<  preparing data ******************************;

PROC SORT DATA = adsl (KEEP = &subj_var.  SASR  &treat_var. );    BY &subj_var. ;RUN;
PROC SORT DATA = pr_all ; BY &subj_var.  VISITNUM PRLNKID;RUN;
PROC SORT DATA = fapr_all ; BY &subj_var.  VISITNUM FALNKID;RUN;

DATA f_pr;
MERGE  pr_all (IN=a) adsl(IN=b) ;
FORMAT PROCCUR $x_ny.  ;
BY &subj_var.  ;
IF b;
RUN;

DATA f_fapr;
MERGE  fapr_all (IN=a) adsl(IN=b) ;
BY &subj_var.  ;
IF b;
RUN;

PROC SQL;
     CREATE TABLE prendbio AS
            SELECT coalesce (a.USUBJID, b.USUBJID) AS USUBJID,
            coalesce (a.VISITNUM, b.VISITNUM) AS VISITNUM  ,
            coalesce (a.VISIT, b.VISIT) AS VISIT,
            a.PRTRT, a.PRLNKID, a.PRSTDTC, a.PROCCUR, a.PRSTAT, a.PRREASND, a.PRSTDTL,
            b.FALNKID, b.FACAT, b.FATESTCD, b.FADTC, b.FATEST, b.FASCAT, b.FAORRES, b.FAEVALID
            FROM pr_all AS a FULL JOIN fapr_all AS b
            ON a.USUBJID = b.USUBJID
            AND a.PRLNKID = b.FALNKID;
QUIT;

DATA pr_fapr;
MERGE  prendbio (IN=a) adsl(IN=b) ;
BY &subj_var.  ;
IF b;
RUN;

***********************< preparing all datasets *****************************;

*******   PR - PRSTAT(Endometrial biopsy performed?), PRREASND (Reason not done) **********;
PROC SORT DATA=f_pr OUT = rsn_ndon
     (KEEP = TRT01AN SASR USUBJID PRSTDTC VISITNUM VISIT PRLNKID PROCCUR PRSTAT PRREASND PRSTDTL);
    BY SASR USUBJID VISITNUM  PRSTDTC PRSTDTL PRLNKID TRT01AN;
RUN;

*************   FAPR - ENDOMETRIAL BIOPSIES -  Biopsy Sample Obtained           ***********;
PROC SORT DATA= pr_fapr OUT = smp_nob
     ( RENAME =( FAORRES = samp_obt) KEEP = USUBJID FAORRES TRT01AN SASR VISITNUM VISIT FALNKID);
    LABEL FAORRES = 'Sample obtained';
    BY SASR USUBJID VISITNUM  TRT01AN;
    FORMAT FAORRES $x_ny.;
    WHERE FATEST = 'Biopsy Sample Obtained' ;
RUN;

*************   FAPR -  ENDOMETRIAL BIOPSIES - Reason sample not obtained ****************;
PROC SORT DATA= pr_fapr OUT = rsn_n_samp
     ( RENAME =( FAORRES = rsn_n_sm_ob) KEEP = USUBJID FAORRES TRT01AN SASR VISITNUM VISIT FALNKID);
    BY SASR USUBJID VISITNUM  TRT01AN;
    WHERE FATEST = 'Reason No Sample Obtained';
RUN;

*************    FAPR -  ENDOMETRIAL BIOPSY - readers record         ****************;
PROC SORT DATA=pr_fapr OUT = end_bps_sort (KEEP = TRT01AN SASR USUBJID VISITNUM VISIT FALNKID FATESTCD FATEST FAEVALID FAORRES);
    BY SASR USUBJID VISITNUM  FALNKID FATESTCD FATEST TRT01AN FAEVALID FAORRES ;
    WHERE FACAT = 'ENDOMETRIAL BIOPSY'  AND FATEST NOT IN( ' ' 'Reason for Inadequate Endometrial Tissue');
RUN;

DATA end_bps_sort;
    LENGTH new_aval $200.;
    SET end_bps_sort;
    IF FAORRES = 'Y' THEN new_aval = 'Yes';
    ELSE IF FAORRES = 'N' THEN new_aval = 'No';ELSE new_aval = propcase(FAORRES );
RUN;

PROC TRANSPOSE DATA = end_bps_sort OUT= end_bps_trans  ;
       BY  SASR USUBJID VISITNUM VISIT FALNKID FATESTCD FATEST TRT01AN ;
       ID FAEVALID;
       VAR new_aval;
       IDLABEL FAEVALID;
RUN;

***************************< merge all datasets ****************************************;

PROC SORT DATA = rsn_ndon;   BY SASR USUBJID VISITNUM VISIT TRT01AN ;RUN;
PROC SORT DATA = smp_nob;    BY SASR USUBJID VISITNUM VISIT TRT01AN ;RUN;
PROC SORT DATA = rsn_n_samp; BY SASR USUBJID VISITNUM VISIT TRT01AN ;RUN;

PROC SQL ;
    CREATE TABLE end_bps_final AS
    SELECT coalesce (x.USUBJID,y.USUBJID, z.USUBJID) AS USUBJID ,
    coalesce (x.SASR,y.SASR, z.SASR) AS SASR 'Subject Identifier/ Age/ Sex/ Race',
    coalesce (x.VISITNUM,y.VISITNUM, z.VISITNUM) AS VISITNUM ,
    coalesce (x.VISIT,y.VISIT, z.VISIT) AS VISIT 'Visit',
    coalesce (x.TRT01AN,y.TRT01AN,z.TRT01AN ) AS TRT01AN format Z_TRT. 'Actual Treatment Group:',
    input(x.PRSTDTC, yymmdd10.) AS newdate ,
    x.PRLNKID, x.PROCCUR  'Endometrial biopsy performed' ,
    x.PRSTAT , x.PRREASND  'Reason not done', x.PRSTDTL  'Date of procedure',
    y.samp_obt,y.FALNKID,
    z.rsn_n_sm_ob  'Reason sample not obtained'
          FROM rsn_ndon AS x
          FULL JOIN smp_nob AS y
          ON x.USUBJID = y.USUBJID AND x.PRLNKID = y.FALNKID
          FULL JOIN rsn_n_samp AS z
          ON x.USUBJID = z.USUBJID AND  x.PRLNKID = z.FALNKID
          ORDER BY x.SASR, x.USUBJID, x.VISITNUM, x.VISIT, x.TRT01AN ;
QUIT;

PROC SORT DATA = end_bps_final OUT = end_bps_final1 NODUPKEY;
    BY TRT01AN SASR USUBJID VISITNUM VISIT PRSTDTL rsn_n_sm_ob;RUN;

PROC SQL ;
        CREATE TABLE all AS
               SELECT coalesce (a.SASR,b.SASR) AS SASR  'Subject Identifier/ Age/ Sex/ Race',
               coalesce (a.VISIT,b.VISIT) AS VISIT  'Visit',
               coalesce (a.TRT01AN,b.TRT01AN) AS TRT01AN format Z_TRT. 'Actual Treatment Group',
               a.newdate , a.PRSTAT, a.PRREASND, a.PRSTDTL, a.samp_obt, a.rsn_n_sm_ob,a.PROCCUR,
               b.FATESTCD , b.FATEST 'Main Diagnosis', b.READER_1   'Reader 1',
               b.READER_2  'Reader 2', b.READER_3  'Reader 3'
               FROM end_bps_final1 AS a LEFT JOIN end_bps_trans AS b
               ON a.USUBJID = b.USUBJID
               AND a.PRLNKID = b.FALNKID;
QUIT;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%MTITLE;

%datalist(
    data     = all
  , page     = &treat_var.
  , by       = SASR VISIT PRSTDTL FATESTCD
  , var      = PROCCUR PRREASND samp_obt rsn_n_sm_ob FATEST READER_1 READER_2 READER_3
  , order    = FATESTCD
  , freeline = SASR
  , optimal  = Y
  , maxlen   = 10
  , split    = '/*'
  , hsplit   = #
  , layout   = Standard
  , bylen    = 10
  , hc_align = CENTER
  , hn_align = CENTER
);

%endprog();
