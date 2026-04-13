/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_3_9_adfapr_enbio);
/*
 * Purpose          : Number of subjects by endometrial biopsy main results  (SAF)
 * Programming Spec :
 * Validation Level : 2 - Independent Programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : epjgw (Roland Meizis) / date: 30JAN2024
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/t_8_3_9_adfapr_enbio.sas (egavb (Reema S Pawar) / date: 14JUN2023)
 ******************************************************************************/


%load_ads_dat(adfapr_view, adsDomain = adfapr, adslWhere = &saf_cond.)
%load_ads_dat(
    mh_hys_view
  , adsDomain = admh
  , where     = mhdecod IN ('Hysterectomy' 'Hysterosalpingectomy' 'Hysterosalpingo-oophorectomy' 'Radical hysterectomy') /* hysterectomy subjects */
  , adslWhere = &saf_cond
)

**************************  %extend_data ***************************;

%extend_data(indat = adfapr_view, outdat = adfapr)
%extend_data(indat = mh_hys_view, outdat = mh_hys)

**************************  removing subjects with hysterectomy  ***************************;

proc sql;
    create table adfapr_wo_hys as
        select *  from adfapr
        where USUBJID not in (select USUBJID from mh_hys)
        order by USUBJID, &treat_var, AVISITN;
QUIT;

*****************select unscheduled records as stated in table footnote*****;
/* "Unscheduled biopsy is performed in case of an abnormal finding in the transvaginal ultrasound and/or if the participant has experienced post-menopausal bleeding during the study." */
data unsched_biopsy;
    set adfapr_wo_hys (where=(PARAMCD EQ 'REUNSEB'
                       AND AVALC NE 'REPEAT BIOPSY DUE TO INSUFFICIENT TISSUE'
                       AND AVISITN EQ 900000));
run;

data adfapr_final;
    merge adfapr_wo_hys
          unsched_biopsy (in=_in_unsched keep=USUBJID &treat_var AVISITN);
    by USUBJID &treat_var AVISITN;

    /* Keep unscheduled records only if they satisfy condition from table footnote */
    if AVISITN = 900000 and not(_in_unsched) then delete;
run;

data bio;
    set adfapr_final(WHERE=((paramcd EQ 'BISAMPOB' and AVALC = 'Y' AND anl01fl = 'Y')
                             OR (paramcd EQ 'ADQENDO1' and anl01fl = 'Y' and dtype = 'MAJCON')));
RUN;

%incidence_print(
    data        = bio
  , by          = avisitn
  , var         = paramcd
  , triggercond = avalc = "Y"
  , total       = NO
  , evlabel     = Diagnosis
  , outdat      = outdat_adqendo1
  , freeline    = avisitn
)

DATA outdat_adqendo1;
    SET outdat_adqendo1(WHERE=(paramcd = 'ADQENDO1'));
RUN;


%** $z_FAPAR.'BENIGEN1' [Benign Endopmetrium];
%** $z_FAPAR.'ENDHYP4Y' [Endometrial Hyperplasia 2014 Criterion];
%** $z_FAPAR.'ENDOPOL1' [Endometrial Polyps];
%** $z_FAPAR.'MALNEOP1' [Malignant Neoplasm];

data result;
    set adfapr_final(WHERE=(paramcd in ('ADQENDO1' 'BENIGEN1' 'ENDHYP4Y' 'ENDOPOL1' 'MALNEOP1') and anl01fl = 'Y' and dtype = 'MAJCON'));
RUN;

%incidence_print(
    data        = result
  , by          = avisitn
  , var         = paramcd
  , triggercond = avalc = 'Y'
  , total       = NO
  , complete    = YES
  , completevar = paramcd
  , evlabel     = Diagnosis
  , outdat      = outdat_majcon
  , freeline    = avisitn
)

DATA outdat_majcon;
    SET outdat_majcon(WHERE=(paramcd in ('BENIGEN1' 'ENDHYP4Y' 'ENDOPOL1' 'MALNEOP1')));
RUN;

** Non-benign result by >= 1 reader (based on all reads);
DATA non_majcon;
    SET adfapr_final(WHERE=(paramcd in ('ADQENDO1' 'BENIGEN1' 'ENDHYP4Y' 'ENDOPOL1' 'MALNEOP1') and dtype NE 'MAJCON'));

    IF paramcd in ('BENIGEN1' 'ENDHYP4Y' 'MALNEOP1');
    flag = 0;
    IF      paramcd = 'BENIGEN1' and avalc = 'N' then flag = 1;
    ELSE IF paramcd = 'ENDHYP4Y' and avalc = 'Y' then flag = 1;
    ELSE IF paramcd = 'MALNEOP1' and avalc = 'Y' then flag = 1;
RUN;

** Add dummy subject with flag = 1 to get a complete BY parameter (AVISITN) in incidence print;
%let dummy_param_class = -999;

DATA dummy_non_majcon;
    SET non_majcon;

    &subj_var. = 'dummy_subject';
    &mosto_param_class. = &dummy_param_class.;
    flag = 1;
RUN;

DATA dummy_adfapr_final;
    SET adfapr_final;
    &subj_var. = 'dummy_subject';
    &mosto_param_class. = &dummy_param_class.;
RUN;

DATA non_majcon_w_dummy;
    SET non_majcon
        dummy_non_majcon;
RUN;
DATA adfapr_w_dummy;
    SET adfapr_final
        dummy_adfapr_final;
RUN;

*****************************************************;
data n_ref;
    set adfapr_w_dummy(WHERE=(paramcd = 'ADQENDO1' and anl01fl = 'Y' and dtype = 'MAJCON'));
RUN;

%incidence_print(
    data        = non_majcon_w_dummy
  , data_n      = n_ref
  , by          = avisitn
  , var         = studyid
  , triggercond = flag = 1
  , total       = NO
  , complete    = YES
  , evlabel     = Diagnosis
  , anytxt      = %str(Non-benign result by >= 1 reader (based on all reads))
  , outdat      = outdat_non_benign
  , freeline    = avisitn
)

PROC SQL NOPRINT;
    SELECT name INTO :_t_dummy SEPARATED BY " "
    FROM dictionary.columns
    WHERE     libname = 'WORK'
          AND upcase(memname) = 'OUTDAT_NON_BENIGN'
          AND upcase(name) LIKE '_T_%'
          AND strip(label) = "&dummy_param_class."
          ;
QUIT;

DATA outdat_non_benign;
    SET outdat_non_benign(DROP=&_t_dummy.); ** Drop dummy treatment;
    _sort1 = 3; ** Just for ordering;
    IF _levtxt = 'Non-benign result by >= 1 reader (based on all reads)';
RUN;

DATA outdat_stack;
    SET outdat_adqendo1
        outdat_majcon
        outdat_non_benign
        ;

    _t_1 = STRIP(_t_1);
    _t_2 = STRIP(_t_2);
    if PARAMCD="ENDOPOL1" then _sort1 = 2;
RUN;

DATA outdat_adqendo1inp;
    SET outdat_adqendo1inp;
    IF keyword = 'DATA' THEN value = 'outdat_stack';
    IF keyword = 'FREELINE' THEN value = '_sort1  ';
RUN;

***************************************;
%MTITLE;


%mosto_param_from_dat(data = outdat_adqendo1inp, var = config)
%datalist(&config.)


/* Use  at the end of each study program */
%endprog;