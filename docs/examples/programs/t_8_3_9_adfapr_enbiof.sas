/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_3_9_adfapr_enbiof);
/*
 * Purpose          : Number of biopsies by endometrial biopsy main results including subcategories  (SAF)
 * Programming Spec :
 * Validation Level : 2 - Independent Programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : epjgw (Roland Meizis) / date: 11DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/t_8_3_9_adfapr_enbiof.sas (egavb (Reema S Pawar) / date: 14JUN2023)
 ******************************************************************************/

%load_ads_dat(
    adfapr_view
  , adsDomain = adfapr
  , where     = ANL01FL EQ "Y"
                AND PARCAT1 IN ("ENDOMETRIAL BIOPSY" "ENDOMETRIAL BIOPSIES" )
                AND (dtype IN( 'MAJCON' 'MAJCWOCI') or PARAMCD EQ 'REUNSEB')
  , adslWhere = &saf_cond
  , adslVars  = &treat_var saffl fasfl
);

%load_ads_dat(
    adpr_view
  , adsDomain = adpr
  , where     = PRTRT = "Endometrial biopsy"
  , adslWhere = &saf_cond
  , adslVars  = &treat_var
);

%load_ads_dat(adsl_view , adsDomain = adsl , where =  &saf_cond )
%load_ads_dat(
    mh_hys_view
  , adsDomain = admh
  , where     = mhdecod IN ('Hysterectomy' 'Hysterosalpingectomy' 'Hysterosalpingo-oophorectomy' 'Radical hysterectomy') /* hysterectomy subjects */
  , adslWhere = &saf_cond
)

**************************  %extend_data ***************************;

%extend_data(indat = adpr_view, outdat = adpr)
%extend_data(indat = adsl_view, outdat = adsl)
%extend_data(indat = adfapr_view, outdat = adfapr)
%extend_data(indat = mh_hys_view, outdat = mh_hys)


**************************  PR - Endometrial biopsy ***************************;

DATA adpr1 ;
     SET adpr ;

     IF AVISITN = 0 THEN AVISITN = 5 ;
     KEEP USUBJID &treat_var AVISITN PROCCUR PRSTAT PRREASND prreasoc;
RUN;

*****************select unscheduled records as stated in table footnote*****;
/* "Unscheduled biopsy is performed in case of an abnormal finding in the transvaginal ultrasound and/or if the participant has experienced post-menopausal bleeding during the study." */
data unsched_biopsy;
    set adfapr (where=(PARAMCD EQ 'REUNSEB'
                       AND AVALC NE 'REPEAT BIOPSY DUE TO INSUFFICIENT TISSUE'
                       AND AVISITN EQ 900000));
run;

**************************  FAPR - Endometrial biopsy ***************************;

DATA adfapr1;
     SET adfapr;
     WHERE PARAMCD IN ('BENIGEN1' 'BENIGEN2'
           'ENDHYP4Y' 'ENDOHYP4' 'ENDHYP3Y' 'ENDOHYP3'
           'MALNEOP1' 'MALNEOP2' 'ENDOPOL1' 'ENDOPOL2')
           and (dtype IN( 'MAJCON' 'MAJCWOCI'));

     FORMAT  result _end_rslt.;
     IF avalc NE '' THEN fastat = 'Y';
     dgn = 'Main diagnosis';
     result = input(upcase(AVALC), _end_rslt_n.);
     KEEP USUBJID &treat_var AVISITN PARCAT1 FAREASND AVALC ANL01FL FAOBJ PARAMCD fastat dgn result;
RUN;

PROC SORT DATA = adpr1 OUT = adpr_sort;BY USUBJID &treat_var AVISITN;RUN;
PROC SORT DATA = adfapr1 OUT = fapr_sort;BY USUBJID &treat_var AVISITN;RUN;
PROC SORT DATA = unsched_biopsy OUT = unsched_biopsy_sort;BY USUBJID &treat_var AVISITN;RUN;


DATA end_bio;
    MERGE adpr_sort (IN=a)
          fapr_sort (IN=b)
          unsched_biopsy_sort (in=_in_unsched keep=USUBJID &treat_var AVISITN);
    BY USUBJID &treat_var AVISITN;
    IF a OR b ;
    FORMAT paramcd;

    /* Keep unscheduled records only if they satisfy condition from table footnote */
    if AVISITN = 900000 and not(_in_unsched) then delete;
RUN;

************************** remove hysterectomy subjects  ***************************;

PROC SQL;
    CREATE TABLE final AS
           SELECT *  FROM end_bio
           WHERE USUBJID NOT IN (SELECT USUBJID FROM mh_hys);
QUIT;

%freq_tab(
    data        = final
  , data_n      = adsl
  , var         = FASTAT dgn PARAMCD*result
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
  , together    = AVISITN
)

DATA one;
    SET one;
    IF _TYPE_ = 1 THEN DELETE;
    IF _TYPE_ = 0 THEN ord= 0;
    IF _TYPE_ = 0 AND _nr_ = 0 THEN dgn = 'Main diagnosis';
    IF _TYPE_ = 0 AND _nr_ IN( 1 2 3 ) THEN DELETE;
    IF PARAMCD IN( 'BENIGEN1' 'BENIGEN2' )THEN  ord = 1;
    IF PARAMCD IN(  'ENDHYP4Y' )THEN  ord = 2;
    IF PARAMCD IN(  'MALNEOP1' )THEN  ord = 3;
    IF PARAMCD IN( 'ENDOPOL1' 'ENDOPOL2') THEN  ord  = 4;
    /* Remove the "- of these:" which is automatically created because we are using subvariables of the form var=var1*var2 */
    _varl_ = tranwrd(_varl_, "- of these: ", "            ");

    IF PARAMCD = 'BENIGEN1' AND _TYPE_ IN (2 2.5) THEN DELETE ;
    IF PARAMCD = 'BENIGEN1' AND result ^= 16 THEN DELETE ;
    IF PARAMCD = 'BENIGEN1' AND result = 16 THEN _varl_ = 'Benign Endometrium' ;

    IF PARAMCD = 'BENIGEN2' AND _TYPE_ IN (2 2.5 ) THEN DELETE ;
    IF PARAMCD = 'BENIGEN2' AND result IN (9 10 11 12 13 14 15 16) THEN DELETE ;

    IF PARAMCD = 'ENDHYP4Y' AND _TYPE_ IN (2 2.5 ) THEN DELETE ;
    IF PARAMCD = 'ENDHYP4Y' AND result = 16 THEN _varl_ = 'Endometrial Hyperplasia (WHO 2014) Criterion';
    IF PARAMCD = 'ENDHYP4Y' AND result IN (1 2 3 4 5 6 7 8 11 12 13 14 15 99 ) THEN DELETE ;

    IF PARAMCD = 'MALNEOP1' AND _TYPE_ IN (2 2.5 ) THEN DELETE ;
    IF PARAMCD = 'MALNEOP1' AND result = 16 THEN _varl_ = 'Malignant Neoplasm' ;
    IF PARAMCD = 'MALNEOP1' AND result IN (1 2 3 4 5 6 7 8 9 10 13 14 15 ) THEN DELETE ;

    IF PARAMCD = 'ENDOPOL1' AND _TYPE_ IN (2 2.5 ) THEN DELETE ;
    IF PARAMCD = 'ENDOPOL1' AND result = 16 THEN _varl_ = 'Endometrial Polyps' ;

    IF PARAMCD = 'ENDOPOL2' AND _TYPE_ IN (2 2.5 ) THEN DELETE ;
    IF PARAMCD = 'ENDOPOL2' AND result IN (2 3 4 5 6 7 8 9 10 11 12 15 16) THEN DELETE ;

    IF AVISITN ^= 900000 AND
        PARAMCD = 'ENDOPOL1' AND result IN (2 3 4 5 6 7 8 9 10 11 12 15) THEN DELETE ;

    IF AVISITN = 900000 AND
        PARAMCD = 'ENDOPOL1' AND result IN (1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 99) THEN DELETE ;

     IF result = 16 THEN _newvar = 1.5;
RUN;


DATA ONEINP;
    SET ONEINP;
    IF keyword = 'BY' THEN value = 'AVISITN ord _newvar dgn _widownr _nr2_ _ord_  _type_ _kind_ _varl_ ';
    IF keyword = 'ORDER' THEN value = '  ord _newvar _widownr _nr2_ _ord_  _type_ _kind_ ';
    IF keyword = 'FREELINE' THEN value = 'ord ';
RUN;

***************************************;

%MTITLE;

%mosto_param_from_dat(data = ONEINP, var = config)
%datalist(&config.)

/* Use  at the end of each study program */
%endprog ;