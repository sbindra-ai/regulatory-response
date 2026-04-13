/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = d_formats, print2file = N);
/*
 * Purpose          : Create permanent formats in library ADS.
 * Programming Spec :
 * Validation Level : 1 - Verification by review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 21NOV2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/d_formats.sas (eokcw (Vijesh Shrivastava) / date: 16SEP2023)
 ******************************************************************************/
/* Changed by       : epjgw (Roland Meizis) / date: 12DEC2023
 * Reason           : Add display format for colombia suicide questionnaire subcategories
 ******************************************************************************/




*******************************************************************************;
*** delete existing format catalog in ads before new one is built
*******************************************************************************;
PROC DATASETS LIBRARY = ads NOLIST NOWARN;
    DELETE &fmtcat (memtype=catalog) fmt_disp (memtype=catalog);
QUIT;


*******************************************************************************;
*** Create format catalog according to the OAD-Metadata and ADS-Metadata
*******************************************************************************;

%create_ads_fmtcat(
    ignoreCodelists = XQSRSCAT XDVSCAT
  , adsCodelists    = X_RACES RACE SEX
  , adsInformats    = X_LBPAR X_LBPARN
  , addFromCodlVars = Y
);



PROC FORMAT LIB=ADS.&fmtcat.;
    INVALUE Z_TRT (JUST UPCASE) /*  SDTMP SE.ETCD */
            'B120'      = 100   /* BAY 3427080 120 mg SD */
            'PLACEBO'   = 101 /* Placebo */
             ;

    INVALUE _aperi (JUST UPCASE)    /* ARMCD#TAETORD = PERIOD  */
            'ELIN120#1'     = 1
            'ELIN120#2'     = 1
            'ELIN120#3'     = 1
            'ELIN120#4'     = 1
            'ELIN120#5'     = 1

            'PLA_ELIN120#1' = 1
            'PLA_ELIN120#2' = 1
            'PLA_ELIN120#3' = 2
            'PLA_ELIN120#4' = 2
            'PLA_ELIN120#5' = 2
            ;
     INVALUE _ultravaln
           'Normal Or Normal Variant' = 1
           'Abnormal'                 = 2
           'Abdominal'                = 3
           'Transrectal'              = 4
           'Transvaginal'             = 5
           ;
     INVALUE _qstptn
           "Lifetime"         = 1
           "Last 6 months"    = 2
           "Last 24 months"   = 3
           "Since last visit" = 4
           ;
     INVALUE _tptn
          "Lifetime" = 1
           "Last 6 Months"    = 2
           "Last 24 Months"   = 3
           "Since Last Visit" = 4
           ;
      INVALUE _extimen
            'During Week 1'= 1
            'During Week 3 & 4'= 2
            'During Week 7 & 8'= 3
            'During Week 11 & 12'= 4;

     INVALUE _cmtimen
           'During Week 1'= 1
           'During Week 4'= 2
           'During Week 8'= 3
           'During Week 12'= 4;

      INVALUE _dstimen
         'Up to Week 1' = 1
         'Up to Week 4' = 2
         'Up to Week 8' = 3
         'Up to Week 12' = 4;

     INVALUE _mamo_rsn_n
          "REFUSED BY SUBJECT" = 1
          "NO IMAGE AVAILABLE" = 2
          "INSUFFICIENT IMAGE" = 3
          "TECHNICAL REASONS" = 4
          "LOST TO FOLLOW-UP" = 5
          "IMAGE QUALITY" = 6
          "COVID-19 PANDEMIC RELATED: SUBJECT SPECIFIC" = 7
          "COVID-19 PANDEMIC RELATED: OTHER"       = 8
          "OTHER" = 9;

     INVALUE _mamo_fnd_n
              'NORMAL'=1
              'ABNORMAL, CLINICALLY INSIGNIFICANT' =2
              'ABNORMAL, CLINICALLY SIGNIFICANT'=3
              'NOT ASSESSABLE'=4;

     INVALUE gyn_rns_nd_n
            "UNSUCCESSFUL ATTEMPT" =1
            "REFUSED BY SUBJECT" =2
            "COVID-19 PANDEMIC RELATED: SUBJECT SPECIFIC" =3
            "COVID-19 PANDEMIC RELATED: OTHER" =4
            "OTHER"=5 ;

     INVALUE _ultr_rsl_n
     'Normal Or Normal Variant' = 1
     'Abnormal'                 = 2
     'Not Assessable'           = 3;

     INVALUE _methodn
            'Abdominal'                = 1
            'Transrectal'              = 2
            'Transvaginal'             = 3 ;

     INVALUE _end_nod_n
     "REFUSED BY SUBJECT" = 1
     "COVID-19 PANDEMIC RELATED: SUBJECT SPECIFIC" =2
     "COVID-19 PANDEMIC RELATED: OTHER" = 3
     "OTHER"   =4;

     INVALUE _end_nsamp_n
     "UNSUCCESSFUL ATTEMPT - IMPOSSIBLE TO INSERT DEVICE" = 1
     "UNSUCCESSFUL ATTEMPT - NO TISSUE" = 2
     "OTHER" = 3;

     INVALUE _unsch_bio_sam_n
             "REPEAT BIOPSY DUE TO INSUFFICIENT TISSUE" = 1
             "THICKENING OF ENDOMETRIUM" = 2
             "POST-MENOPAUSAL BLEEDING" = 3
             "OTHER" = 4;

      INVALUE _crv_cty_n
            "UNSUCCESSFUL ATTEMPT" = 1
            "REFUSED BY SUBJECT" = 2
            "COVID-19 PANDEMIC RELATED: SUBJECT SPECIFIC" =3
            "COVID-19 PANDEMIC RELATED: OTHER" = 4
            "OTHER" = 5   ;

      INVALUE _crv_cty_rstn
            "Y" = 1
            "N" = 2
            "NOT ASSESSABLE" =3 ;

      invalue _end_rslt_n
            'ATROPHIC' = 1
            'INACTIVE' = 2
            'PROLIFERATIVE' = 3
            'DISORDERED PROLIFERATIVE' = 4
            'SECRETORY' = 5
            'MENSTRUAL' = 6
            'ENDOMETRITIS' = 7
            'OTHER' = 8
            'HYPERPLASIA WITHOUT ATYPIA' = 9
            'ATYPICAL HYPERPLASIA / ENDOMETRIOID INTRAEPITHELIAL NEOPLASIA (EIN)' = 10
            'ENDOMETRIAL NEOPLASM' = 11
            'OTHER MALIGNANT NEOPLASM' = 12
            'FUNCTIONAL' = 13
            'HYPERPLASTIC NOS'  = 14
            'N' = 15
            'Y' = 16
            'NO CONSENSUS' = 99
            ;

      inVALUE _vitn
          'HR'    = 1
          'SYSBP' = 2
          'DIABP' = 3 ;

RUN;




/******************************************************************************
 * NOTE: Requested informats are needed to process inline metadata
 ******************************************************************************/

%format2informat(
    format            = RACE
  , FirstOnConflictNY = Y
);

%format2informat(
    format            = SEX
  , FirstOnConflictNY = Y
);



******************************************************************************;
*** Add descriptive formats for below SP formats only be used for table display;
******************************************************************************;

/*%addCodelist2Catalog(*/
/*    codeDat    = CODEL_SP.ny*/
/*  , fmtCatalog = ADS.FMT_DISP*/
/*  , formatName = _ny*/
/*  , labelVar   = descrip*/
/*);*/

%addCodelist2Catalog(
    codeDat    = CODEL_SP.sex
  , fmtCatalog = ADS.FMT_DISP
  , formatName = _sex
  , labelVar   = descrip
);

%addCodelist2Catalog(
    codeDat    = CODEL_SP.country
  , fmtCatalog = ADS.FMT_DISP
  , formatName = _country
  , labelVar   = descrip
);

%addCodelist2Catalog(
    codeDat    = CODELIST.X_QS2PR
  , fmtCatalog = ADS.FMT_DISP
  , formatName = _qs2pr
  , labelVar   = lbl_ana2
);


******************************************************************************;
*** Add display specific formats which will only be used for table display    ;
******************************************************************************;

PROC FORMAT LIB=ADS.FMT_DISP;
    VALUE _trt
          1='P-E'
          0='E'
          ;
    VALUE _ynm
        1='No'
        2='Yes'
        3= 'Missing'
    ;
    VALUE _phs
     1 = "Elinzanetant 120mg#Week 1-12"
     2 = "Placebo#Week 1-12"
     3 = "Elinzanetant 120mg#Week 13-26^&super_a"
     4 = "Placebo - Elinzanetant 120mg#Week 13-26^&super_b"
     5 = "Elinzanetant 120mg# Week 1-26^&super_c"
     6 = "Total";

    VALUE _crit
     1 = "at least 1 day"
     2 = "at least 4 weeks"
     3 = "at least 12 weeks"
     4 = "at least 25 weeks";

    VALUE _smk
     1 = "Never"
     2 = "Former"
     3 = "Current"
     4 = "Never Or Former";

    VALUE _ny
     0 = "No"
     1 = "Yes"
     2 = "Not Applicable"
     3 = "Unknown"
     4 = "Not assessable";

    VALUE _weekf
     1 = 'Week 1'
     2 = 'Week 4'
     3 = 'Week 8'
     4 = 'Week 12';

    VALUE _acn
         1 = 'Dose not changed'
         2 = 'Drug interrupted'
         3 = 'Drug withdrawn'
         4 = 'Not applicable';

     VALUE _qstpt
         1 = "Lifetime"
         2 = "In the last 6 months"
         3 = "In the last 24 months"
         4 = "Since last visit";


     VALUE _cat
        1 = "Suicidal Ideation (Category 1-5)"
        2 = "Suicidal Behavior (Category 6-10)"
        3 = "Suicidal Ideation or Behavior (Category 1-10)";

     VALUE _eq5d
     1     =     'Mobility'
     2     =     'Self-Care'
     3     =     'Usual Activities'
     4     =     'Pain/Discomfort'
     5     =     'Anxiety/Depression'
     ;


     VALUE _ultraval
      1     = 'Normal Or Normal Variant'
      2     = 'Abnormal'
      3     = 'Abdominal'
      4     = 'Transrectal'
      5     = 'Transvaginal'
      ;

     VALUE $_prawsf
           'Not at all'    = 1
           'A little bit'  = 2
           'Somewhat'      = 3
           'Quite a bit'   = 4
           'Very much'     = 5   ;

       VALUE _prawsf
              1 =  'Not at all'
              2 =  'A little bit'
              3 =  'Somewhat'
              4 =  'Quite a bit'
              5 =  'Very much'                ;

       VALUE $_prawsfs
            'Very much'    = 1
            'Quite a bit'  = 2
            'Somewhat'     = 3
            'A little bit' = 4
            'Not at all'   = 5  ;

       VALUE _prawsfs
           1 =    'Very much'
           2 =    'Quite a bit'
           3 =    'Somewhat'
           4 =    'A little bit'
           5 =    'Not at all'    ;

        VALUE $_prawss
       'Never'       = 1
       'Rarely'      = 2
       'Sometimes'   = 3
       'Often'       = 4
       'Always'      = 5   ;

       VALUE _prawss
          1 =  'Never'
          2 =  'Rarely'
          3 =  'Sometimes'
          4 =  'Often'
          5 =  'Always'                ;

        VALUE $_prawsse
           'Always'      = 1
           'Often'       = 2
           'Sometimes'   = 3
           'Rarely'      = 4
           'Never'       = 5   ;

        VALUE _prawsse
             1 =    'Always'
             2 =    'Often'
             3 =    'Sometimes'
             4 =    'Rarely'
             5 =    'Never' ;

        VALUE $_prawse
           'Very good'      = 1
           'Good'           = 2
           'Fair'           = 3
           'Poor'           = 4
           'Very poor'      = 5   ;

        VALUE _prawse
              1 =  'Very good'
              2 =  'Good'
              3 =  'Fair'
              4 =  'Poor'
              5 =  'Very poor'                ;

        VALUE $_pgicmsf
         'MUCH LESS'             = 1
         'A LITTLE LESS'         = 2
         'THE SAME (NO CHANGE)'  = 3
         'A LITTLE MORE'         = 4
         'MUCH MORE'             = 5   ;

      VALUE _pgicmsf
             1 =  'Much less'
             2 =  'A little less'
             3 =  'The same (no change)'
             4 =  'A little more'
             5 =  'Much more'                ;


        VALUE $_pgicssf
            'MUCH BETTER'           = 1
            'A LITTLE BETTER'       = 2
            'THE SAME (NO CHANGE)'  = 3
            'A LITTLE WORSE'        = 4
            'MUCH WORSE'            = 5   ;

       VALUE _pgicssf
       1 =  'Much better'
       2 =  'A little better'
       3 =  'The same (no change)'
       4 =  'A little worse'
       5 =  'Much worse'                ;



     VALUE $_mshf
         'NO HOT FLASHES' = 1
         'RARELY'         = 2
         'SOMETIMES'      = 3
         'OFTEN'          = 4
         'VERY OFTEN'     = 5   ;

    VALUE _mshf
      1     =     'No hot flashes'
      2     =     'Rarely'
      3     =     'Sometimes'
      4     =     'Often'
      5     =     'Very often';

    VALUE $_shf
         'NO HOT FLASHES' = 6
         'MILD'           = 7
         'MODERATE'       = 8
         'SEVERE'         = 9
         'VERY SEVERE'    = 10  ;


      VALUE _shf
              6     =      'No hot flashes'
              7     =      'Mild'
              8     =      'Moderate'
              9     =      'Severe'
              10    =      'Very severe'  ;

      VALUE $_ssp
         'NO SLEEP PROBLEMS' = 11
         'MILD'              = 12
         'MODERATE'          = 13
         'SEVERE'            = 14
         'VERY SEVERE'       = 15 ;


       VALUE _ssp
        11    =      'No sleep problems'
        12    =      'Mild'
        13    =      'Moderate'
        14    =      'Severe'
        15    =      'Very severe'   ;


       VALUE $_eqm
          'I have no problems walking'          = 0
          'I have slight problems walking'      = 1
          'I have moderate problems walking'    = 2
          'I have severe problems walking'      = 3
          'I am unable to walk'                 = 4    ;

       VALUE _eqm
          0 =  'I have no problems walking'
          1 =  'I have slight problems walking'
          2 =  'I have moderate problems walking'
          3 =  'I have severe problems walking'
          4 =  'I am unable to walk'     ;


     VALUE $_eqsc
         'I have no problems washing or dressing myself'          = 5
         'I have slight problems washing or dressing myself'      = 6
         'I have moderate problems washing or dressing myself'    = 7
         'I have severe problems washing or dressing myself'      = 8
         'I am unable to wash or dress myself'                    = 9     ;


      VALUE _eqsc
            5  =   'I have no problems washing or dressing myself'
            6  =    'I have slight problems washing or dressing myself'
            7  =    'I have moderate problems washing or dressing myself'
            8  =    'I have severe problems washing or dressing myself'
            9  =    'I am unable to wash or dress myself'                    ;


       VALUE _equa
           10    =     'I have no problems doing my usual activities'
           11    =     'I have slight problems doing my usual activities'
           12    =     'I have moderate problems doing my usual activities'
           13    =     'I have severe problems doing my usual activities'
           14    =     'I am unable to do my usual activities'  ;


       VALUE $_equa
           'I have no problems doing my usual activities'        = 10
           'I have slight problems doing my usual activities'    = 11
           'I have moderate problems doing my usual activities'  = 12
           'I have severe problems doing my usual activities'    = 13
           'I am unable to do my usual activities'               = 14   ;


        VALUE _eqpd
            15    =     'I have no pain or discomfort'
            16    =     'I have slight pain or discomfort'
            17    =     'I have moderate pain or discomfort'
            18    =     'I have severe pain or discomfort'
            19    =     'I have extreme pain or discomfort'   ;



        VALUE $_eqpd
            'I have no pain or discomfort'       = 15
            'I have slight pain or discomfort'   = 16
            'I have moderate pain or discomfort' = 17
            'I have severe pain or discomfort'   = 18
            'I have extreme pain or discomfort'  = 19       ;

         VALUE _eqad
             20    =     'I am not anxious or depressed'
             21    =     'I am slightly anxious or depressed'
             22    =     'I am moderately anxious or depressed'
             23    =     'I am severely anxious or depressed'
             24    =     'I am extremely anxious or depressed' ;

         VALUE $_eqad
             'I am not anxious or depressed'        = 20
             'I am slightly anxious or depressed'   = 21
             'I am moderately anxious or depressed' = 22
             'I am severely anxious or depressed'   = 23
             'I am extremely anxious or depressed'  = 24 ;

         VALUE _cmtime
            1 = 'During Week 1'
            2 = 'During Week 4'
            3 = 'During Week 8'
            4 = 'During Week 12';

         VALUE _dstime
         1= 'Up to Week 1'
         2= 'Up to Week 4'
         3 = 'Up to Week 8'
         4 = 'Up to Week 12'
;

         VALUE _extime
         1     = 'During Week 1'
         2     = 'During Week 3 & 4'
         3     = 'During Week 7 & 8'
         4     = 'During Week 11 & 12'
         ;

          VALUE _mamo_rs
           1 = 'Refused by subject'
           2 = 'No image available'
           3 = 'Insufficient image'
           4 = 'Technical reasons'
           5 = 'Lost to follow-up'
           6 = 'Image quality'
           7 = 'Covid-19 Pandemic related: subject specific'
           8 = 'Covid-19 Pandemic related: other'
           9 = 'Other';

          VALUE _mamo_fnd
                 1 ='Normal'
                 2 ='Abnormal, clinically insignificant'
                 3 ='Abnormal, clinically significant'
                 4 ='Not assessable';

         VALUE $_edu
              'College or university education' = 1
              'Professional certification'           = 2
              'Attending college'       = 3
              'Other'         = 4;

         VALUE _edu
         1 = 'College or university education'
         2 = 'Professional certification'
         3 = 'Attending college'
         4 = 'Other';

         VALUE gyn_rns_nd
          1= 'Unsuccessful attempt'
          2= 'Refused by subject'
          3= 'Covid-19 pandemic related: subject specific'
          4= 'Covid-19 pandemic related: other'
          5=  'Other';

         VALUE _ultr_rsl
         1= 'Normal Or Normal Variant'
         2 ='Abnormal'
         3 = 'Not Assessable'          ;

         VALUE _gyn_ultr_perf
             1 = 'Ultrasound - Uterus and Ovaries'
             2 = 'Ultrasound - Uterus'
             3 = 'Ultrasound - Ovaries';

         VALUE _method
         1 = 'Abdominal'
         2 = 'Transrectal'
         3 = 'Transvaginal';

         VALUE _end_nod
             1 =  "Refused by subject"
             2 = "Covid-19 pandemic related: subject specific"
             3 =  "Covid-19 pandemic related: other"
             4 =  "Other"   ;

         VALUE _end_nsamp
         1 = "Unsuccessful attempt - impossible to insert device"
         2 = "Unsuccessful attempt - no tissue"
         3 = "Other" ;

         VALUE _unsch_bio_sam
         /*1 = "Repeat biopsy due to insufficient tissue"*//* Should not be displayed in table */
         2 = "Thickening of endometrium"
         3 = "Post-menopausal bleeding"
         4 = "Other" ;

          VALUE _crv_cty
                1 = "Unsuccessful attempt"
                2 = "Refused by subject"
                3 = "Covid-19 pandemic related: subject specific"
                4 = "Covid-19 pandemic related: other"
                5 = "Other"          ;

          VALUE _crv_cty_rst
                1 = "Normal or clinically insignificant"
                2 = "Clinically significant result requiring FU"
                3 = "Not assessable"               ;



          VALUE _vit
           1 =  'Heart Rate (beats/min)'
           2 =  'Systolic Blood Pressure (mmHg)'
           3 =  'Diastolic Blood Pressure (mmHg)';

          VALUE _reader
          1 = 'All reader results'
          2 = 'At least one reader result, but not all reader results'
          3 = 'No reader results';

          value _end_rslt
                1 = 'Atrophic'
                2 = 'inactive'
                3 = 'Proliferative'
                4 = 'Disordered proliferative'
                5 = 'Secretory'
                6 = 'Menstrual'
                7 = 'Endometritis'
                8 = 'Other'
                9 = 'Hyperplasia without atypia'
                10 = 'Atypical hyperplasia / endometrioid intraepithelial neoplasia (EIN)'
                11 = 'Endometrial neoplasm'
                12 = 'Other malignant neoplasm'
                13 = 'Functional'
                14 = 'Hyperplastic NOS'
                15 = 'N'
                16 = 'Y'
                99 = 'No consensus'
                ;


           VALUE $_race
                'White'                               = 1
                'Black or African American'           = 2
                'Asian'                               = 3
                'American Indian or Alaska Native'    = 4
                'Multiple'                            = 5
                'Not reported'                        = 6
                ;

           VALUE _race
                1   = 'White'
                2   = 'Black or African American'
                3   = 'Asian'
                4   = 'American Indian or Alaska Native'
                5   = 'Multiple'
                6   = 'Not reported'
                 ;

           VALUE $_ethnic
               'Not Hispanic or Latino'       = 1
               'Hispanic or Latino'           = 2
               'Not reported'                 = 3
               ;

           VALUE _ethnic
               1   = 'Not Hispanic or Latino'
               2   = 'Hispanic or Latino'
               3   = 'Not reported'

                ;

           VALUE  _suicidal_ideation_subcat
              1 = "Wish to be dead or wake up"
              2 = "Nonspecific thoughts"
              3 = "Specific thoughts of method"
              4 = "Some intent to act, no plan"
              5 = "Specific plan and intent"
              ;
           VALUE  _suicidal_behavior_subcat
              1 = "Actual Suicide Attempts"
              2 = "Interrupted Attempts"
              3 = "Aborted Attempts"
              4 = "Preparatory Actions"
              5 = "Non-suicidal Self-injourious Behaviors"
              ;
           value _plotvis
             0 = "Baseline"
            10 = "Week 1"
            20 = "Week 2"
            30 = "Week 3"
            40 = "Week 4"
            50 = "Week 5"
            60 = "Week 6"
            70 = "Week 7"
            80 = "Week 8"
            90 = "Week 9"
           100 = "Week 10"
           110 = "Week 11"
           120 = "Week 12"
           130 = "Week 13"
           140 = "Week 14"
           150 = "Week 15"
           160 = "Week 16"
           170 = "Week 17"
           180 = "Week 18"
           190 = "Week 19"
           200 = "Week 20"
           210 = "Week 21"
           220 = "Week 22"
           230 = "Week 23"
           240 = "Week 24"
           250 = "Week 25"
           260 = "Week 26"
           261 = "Week 26/EoT"
           300 = "Follow-up"
           310 = "Follow-up week 1"
           320 = "Follow-up week 2"
           330 = "Follow-up week 3"
           340 = "Follow-up week 4"
           ;

RUN;




/******************************************************************************
 * End of program
 ******************************************************************************/
%endprog;
