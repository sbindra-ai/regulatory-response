/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_8_3_speg_msmt);
/*
 * Purpose          : Electrocardiogram measurements
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 17OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_8_3_speg_msmt.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/
%load_ads_dat(adsl_view , adsDomain = adsl , where =  &saf_cond  )
%extend_data(indat = adsl_view, outdat = adsl)

PROC SQL;
    CREATE TABLE new_eg AS
           SELECT a.*, b.SASR, b.TRT01AN
           FROM sp.eg AS a LEFT JOIN ads.adsl AS b
           ON a.USUBJID = b.USUBJID;
QUIT;

%extend_data(indat = new_eg, outdat = new_eg2)

*********************< creating listing dates  ************************************;

%m_create_dtl(inputds=new_eg2, varname= EGDTL);
%m_create_dtl(inputds=new_eg2, varname= EGRFTDTL);


**********************< merge with adsl *************************;

PROC SORT DATA = adsl (KEEP = &subj_var. SASR &treat_var_listings_part. &treat_var. );
    BY &treat_var. &subj_var. SASR;RUN;
PROC SORT DATA = new_eg2 ;
    BY &treat_var. &subj_var. SASR VISITNUM EGDTC;;RUN;

DATA eg_final;
MERGE  adsl (IN=a) new_eg2(IN=b) ;
BY  &treat_var. &subj_var. SASR;
IF b;
RUN;

*************************< creating listing variable  ******************************;

DATA eg_1;
    SET eg_final;
    ecg_date = put(input(EGDTC ,yymmdd10.), date9.);
    LABEL EGDTL = 'Electrocardiogram Date'
          VISIT = 'Visit'
          EGTEST = 'Electrocardiogram Parameter'
          EGORRES  = 'Result'
          EGORRESU = 'Standard Unit'
          TRT01AN = 'Actual Treatment Group';
    WHERE EGCAT = 'MEASUREMENT' ;
RUN;

PROC SORT DATA= eg_1 OUT = final ;
    BY &subj_var. SASR VISIT &treat_var. EGDTL EGTEST EGORRES EGORRESU ;
RUN;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%MTITLE;

%datalist(
    data     = final
  , page     = &treat_var.
  , by       = SASR VISIT EGDTL
  , var      = EGTEST EGORRES EGORRESU
  , optimal  = y
  , maxlen   = 35
  , space    = 3
  , split    =
  , hsplit   = #
  , bylen    = 16
  , hc_align = CENTER
  , hn_align = CENTER
);

%endprog();