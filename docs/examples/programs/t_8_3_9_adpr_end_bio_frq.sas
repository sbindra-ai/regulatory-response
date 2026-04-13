/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_3_9_adpr_end_bio_frq);
/*
 * Purpose          : Number of subjects with endometrial biopsy information (SAF)
 * Programming Spec :
 * Validation Level : 2 - Independent Programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : epjgw (Roland Meizis) / date: 12DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/t_8_3_9_adpr_end_bio_frq.sas (egavb (Reema S Pawar) / date: 16JUN2023)
 ******************************************************************************/
/* Changed by       : eokcw (Vijesh Shrivastava) / date: 15DEC2023
 * Reason           : Updated to exclude ANL01FL = 'y' option as this table is not based on majority read.
 ******************************************************************************/
/* Changed by       : epjgw (Roland Meizis) / date: 04JAN2024
 * Reason           : Update and fix numbers for Biopsy sample obtained
 ******************************************************************************/

%load_ads_dat(
    adpr_view
  , adsDomain = adpr
  , where     = PRTRT = "Endometrial biopsy"
  , adslWhere = &saf_cond
  , adslVars  = &treat_var
);

%load_ads_dat(
    adfapr_view
  , adsDomain = adfapr
  /*, where     = ANL01FL = 'Y'*/
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

%extend_data(indat = adpr_view,   outdat = adpr_w_hyst_subj)
%extend_data(indat = adsl_view,   outdat = adsl_w_hyst_subj)
%extend_data(indat = adfapr_view, outdat = adfapr_w_hyst_subj)
%extend_data(indat = mh_hys_view, outdat = mh_hys)


***************** removing subjects with hysterectomy *********************;

PROC SQL;
    CREATE TABLE adpr AS
           SELECT *  FROM adpr_w_hyst_subj
           WHERE USUBJID NOT IN (SELECT USUBJID FROM mh_hys);
QUIT;

PROC SQL;
    CREATE TABLE adsl AS
           SELECT *  FROM adsl_w_hyst_subj
           WHERE USUBJID NOT IN (SELECT USUBJID FROM mh_hys);
QUIT;


PROC SQL;
    CREATE TABLE adfapr AS
           SELECT *  FROM adfapr_w_hyst_subj
           WHERE USUBJID NOT IN (SELECT USUBJID FROM mh_hys);
QUIT;


*********************  Endometrial biopsy performed  *************;

DATA adpr_end_bio;
     SET adpr;

     FORMAT Proccur $x_ny.  PRREASND1 _end_nod.;
     LABEL Proccur = 'Endometrial biopsy performed'
           PRREASND1 = 'Reason:';

     PRREASND1 = input(PRREASND, _end_nod_n.);
     IF AVISITN = 0 THEN AVISITN = 5;
     KEEP USUBJID &treat_var AVISITN PROCCUR PRSTAT PRREASND  PRREASND1 prreasoc ASTDT PRTRT;
RUN;

*****************Of these: Biopsy sample obtained  ************;

DATA adfapr_biosmpl ;
     SET adfapr (where=(PARCAT1 IN('ENDOMETRIAL BIOPSIES')));

     /*<#orange For parameter "Reason No Sample Obtained" keep only the values specified in eCRF */
     /* Reason: For Reason No Sample Obtained = Other, the verbatim reason for other is mapped to same parameter,
        so we have multiple records for same subject and visit  */
     if paramcd = "REANOBIO" and avalc not in ('OTHER' 'UNSUCCESSFUL ATTEMPT - IMPOSSIBLE TO INSERT DEVICE' 'UNSUCCESSFUL ATTEMPT - NO TISSUE') then delete;

     KEEP USUBJID &treat_var AVISITN PARAMCD AVALC FALNKID ADT ANL01FL;
RUN;

PROC SORT DATA=adfapr_biosmpl
          out=adfapr_biosmpl_sort;
    BY USUBJID &treat_var AVISITN PARAMCD ADT;
RUN;

/* Keep only last record per visit and parameter (ordered by date) */
/* Some unsuccessful biopsies were redone, so we have duplicate records. Only the last record is the correct one */
data adfapr_biosmpl_no_dup;
    set adfapr_biosmpl_sort;
    BY USUBJID &treat_var AVISITN PARAMCD ADT;

    if last.paramcd;
run;

PROC TRANSPOSE DATA=adfapr_biosmpl_no_dup OUT=adfapr_biosmpl_t ( DROP= _NAME_ _LABEL_);
    ID PARAMCD;
    VAR AVALC;
    BY USUBJID &treat_var AVISITN;
    IDLABEL paramcd;
RUN;

DATA adfapr_biosmpl_t;
    SET adfapr_biosmpl_t;
    FORMAT Biopsy_Sample_Obtained $x_ny.
           Rsn_N_Smp_Ob _end_nsamp.
           Rs_Unsc_BioSa _unsch_bio_sam.;
    LABEL Rsn_N_Smp_Ob = 'Reason:'
          Rs_Unsc_BioSa = 'Reason for unplanned procedure:';

    Rsn_N_Smp_Ob = input(Reason_No_Sample_Obtained, _end_nsamp_n.);
    Rs_Unsc_BioSa = input(Reason_for_Unscheduled_Biopsy_Sa,_unsch_bio_sam_n. );
RUN;

******************************reader count ( dtype ne MAJCON )***************;

DATA adfapr_readerresults;
     SET adfapr ;
     WHERE PARCAT1 IN( "ENDOMETRIAL BIOPSY" )
           AND PARCAT2 NOT IN (''  'OTHER' )
           AND PARAMCD = 'ADQENDO1'
           AND DTYPE ^= 'MAJCON';
     KEEP USUBJID &treat_var AVISITN PARCAT1 PARCAT2 FAREASND FAOBJ AVALC PARAMCD FAEVALID FALNKID ADT ANL01FL;
RUN;

PROC SORT DATA=adfapr_readerresults (WHERE= (FAEVALID ^= '' ))
          OUT=adfapr_readerresults_sort
          NODUPKEY;
    BY USUBJID &treat_var PARAMCD AVISITN  FAEVALID ;
RUN;

PROC TRANSPOSE DATA=adfapr_readerresults_sort
               OUT=adfapr_readerresults_t ( DROP= _NAME_ _LABEL_);
    ID FAEVALID;
    VAR AVALC;
    BY  USUBJID &treat_var PARAMCD AVISITN;
RUN;


*****************select unscheduled records as stated in table footnote*****;
/* "Unscheduled biopsy is performed in case of an abnormal finding in the transvaginal ultrasound and/or if the participant has experienced post-menopausal bleeding during the study." */

data unsched_biopsy;
    set adfapr_biosmpl_no_dup (where=(PARAMCD EQ 'REUNSEB'
                                    AND AVALC NE 'REPEAT BIOPSY DUE TO INSUFFICIENT TISSUE'
                                    AND AVISITN EQ 900000));
run;


*****************  merge all tables *********************;

PROC SORT DATA = adpr_end_bio;           BY USUBJID &treat_var AVISITN; RUN;
PROC SORT DATA = adfapr_biosmpl_t;       BY USUBJID &treat_var AVISITN; RUN;
PROC SORT DATA = adfapr_readerresults_t; BY USUBJID &treat_var AVISITN; RUN;
PROC SORT DATA = unsched_biopsy;         BY USUBJID &treat_var AVISITN; RUN;

DATA final;
    MERGE adpr_end_bio           (IN=a)
          adfapr_biosmpl_t       (IN=b DROP= Reason_No_Sample_Obtained Reason_for_Unscheduled_Biopsy_Sa)
          adfapr_readerresults_t (IN=c)
          unsched_biopsy         (in=_in_unsched drop=paramcd);
    BY USUBJID &treat_var AVISITN;
    IF a;

    /* Keep unscheduled records only if they satisfy condition from table footnote */
    if AVISITN = 900000 and not(_in_unsched) then delete;

    label Biopsy_Sample_Obtained = 'Of these: Biopsy sample obtained';
    ATTRIB rdr FORMAT = _reader. LABEL = 'Of these:';

    if Biopsy_Sample_Obtained = 'Y' then do;
        IF READER_1 NE '' AND READER_2 NE '' AND READER_3 NE '' THEN rdr = 1;
        IF READER_1 =  '' OR  READER_2 =  '' OR  READER_3 =  '' THEN rdr = 2;
        IF READER_1 =  '' AND READER_2 =  '' AND READER_3 =  '' THEN rdr = 3;
    end;
RUN;


********************* all visit except unscheduled - Generating report ************************;

%freq_tab(
    data        = final (where=(AVISITN NOT IN (900000 .)))
  , data_n      = adsl
  , var         = PROCCUR*PRREASND1   Biopsy_Sample_Obtained*Rsn_N_Smp_Ob   Biopsy_Sample_Obtained*rdr
  , subject     = &subj_var.
  , by          = AVISITN
  , total       = NO
  , class       = &treat_var
  , basepct     = N_MAIN
  , levlabel    = YES
  , header_bign = NO
  , misstext    =
  , outdat      = base
  , missing     = NO
  , complete    = ALL
  , freeline    = avisitn
  , together    = avisitn
)

DATA base2;
    SET base;
    IF strip(_varl_) = 'n' then do;
        if _var_ NE "PROCCUR PRREASND1" then delete; /* keep only first n */
        _varl_ = strip(_varl_); /* fix indentation */
        _newvar = 0; /* fix line order */
    end;

    /* Fix indentation of subcategories of "Yes" results */
    if _var_ = 'BIOPSY_SAMPLE_OBTAINED RSN_N_SMP_OB' then _varl_ = '      ' || _varl_;

    /* Fix indentation of subcategories of "Yes" results */
    if _var_ = 'BIOPSY_SAMPLE_OBTAINED RDR' then _varl_ = '      ' || _varl_;

    if _nr_ = 2 and Biopsy_Sample_Obtained = 'Y' then delete;
    if _nr_ = 3 and Biopsy_Sample_Obtained in( 'N' '' )then delete;

    /* Remove the "- of these:" which is automatically created because we are using subvariables of the form var=var1*var2 */
    _varl_ = tranwrd(_varl_, "- of these: ", "            ");
RUN;

********************* unscheduled - Generating report ************************;

%freq_tab(
    data        = final (where=(AVISITN = 900000))
  , data_n      = adsl
  , var         = PROCCUR*PRREASND1    Biopsy_Sample_Obtained*Rs_Unsc_BioSa    Biopsy_Sample_Obtained*rdr
  , subject     = &subj_var.
  , by          = AVISITN
  , total       = NO
  , class       = &treat_var
  , basepct     = N_MAIN
  , levlabel    = YES
  , header_bign = NO
  , misstext    =
  , outdat      = unschedul
  , missing     = NO
  , complete    = ALL
  , freeline    =
)

DATA unschedul2;
    SET unschedul;

    IF strip(_varl_) = 'n' then do;
        if _var_ NE "PROCCUR PRREASND1" then delete; /* keep only first n */
        _varl_ = strip(_varl_); /* fix indentation */
        _newvar = 0; /* fix line order */
    end;

    /* Remove 'No' lines */
    IF _TYPE_ = 2 AND _varl_ = '   No' THEN DELETE;

    if _var_ = "BIOPSY_SAMPLE_OBTAINED RDR" and _type_ in (0, 2) then delete;

    /* Fix indentation of subcategories of "Yes" results */
    if _var_ = 'BIOPSY_SAMPLE_OBTAINED RS_UNSC_BIOSA' then _varl_ = '      ' || _varl_;
    if _var_ = 'BIOPSY_SAMPLE_OBTAINED RDR'           then _varl_ = '      ' || _varl_;

    /* Remove the "- of these:" which is automatically created because we are using subvariables of the form var=var1*var2 */
    _varl_ = tranwrd(_varl_, "- of these: ", "            ");
RUN;


*************************merge and print table ******************;

DATA all_stack;
    SET base2
        unschedul2;
RUN;

DATA all_stackinp;
    SET baseinp;
    IF keyword = 'DATA' THEN value = 'all_stack';
RUN;


%MTITLE;

%mosto_param_from_dat(data = ALL_STACKINP, var = config)
%datalist(&config.)


/* Use  at the end of each study program */
%endprog;