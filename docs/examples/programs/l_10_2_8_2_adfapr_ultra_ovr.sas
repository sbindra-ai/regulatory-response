/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_8_2_adfapr_ultra_ovr);
/*
 * Purpose          : Medication of Interest - Liver Event
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 17OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_8_2_adfapr_ultra_ovr.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/

%m_create_ads_view(adsDomain = adfapr, outDat = adfaprall)

%extend_data(indat = adfaprall, outdat = adfapr)

*************************< creating listing dates  *****************************;

DATA adfaprall_1;
    SET adfapr;
    WHERE FAOBJ= 'ULTRASOUND PELVIS'
          AND PARCAT2 = 'ULTRASOUND OVARIES VISUALIZED'
          and &saf_cond;
RUN;

%m_create_dtl(inputds=adfaprall_1, varname= FADTL);

*************************< creating listing variables *************************;

PROC SORT DATA = adfaprall_1 OUT = adfapr_1;
     BY UASR USUBJID AVISITN TRT01AN FASPID;
RUN;

DATA adfapr_2 ;
    SET adfapr_1;
    BY SASR USUBJID AVISITN TRT01AN FASPID;
     FORMAT new_avalc $200. new_test $200. testnum 8.;
          IF AVALC = 'Y' THEN new_avalc = 'YES';
          ELSE IF AVALC = 'N' THEN new_avalc = 'NO';
          ELSE new_avalc = AVALC ;
          IF upcase(FALAT )= 'RIGHT' THEN DO new_FALAT = 'RIGHT' ; nlat = 1;END;
          IF upcase(FALAT )= 'LEFT' THEN DO new_FALAT = 'LEFT'  ;nlat = 2;END;
                IF FATEST = 'Ovary Visualized' THEN DO; testnum = 1 ; new_test = 'OV'; END  ;
           ELSE IF FATEST = 'Ovary Largest Diameter' THEN DO; testnum = 2 ;new_test ='OLD';END;
           ELSE IF FATEST = 'Ovary Diam Perpendicular to Largest Diam' THEN DO; testnum = 3 ; new_test = 'ODPLD';END;
           ELSE IF FATEST = 'Cyst Like Structure Visualized' THEN DO; testnum= 4; new_test = 'CLSV';END;
           ELSE IF FATEST = 'Type of Cyst Like Structure' THEN DO; testnum= 5 ; new_test = 'TOCS';END;
           ELSE IF FATEST = 'Follicle-Like Structure Demonstrable' THEN DO; testnum= 6 ; new_test = 'FLSD';END;
           ELSE IF FATEST = 'Evidence of Ruptured Follicle' THEN DO; new_test = 'EORF'; testnum =7 ;END;
           ELSE IF FATEST = 'Largest Diameter' THEN DO; new_test = 'LD'; testnum =8 ;END;
           ELSE IF FATEST = 'Diameter Perpendicular to Largest Diam' THEN DO;  new_test = 'DPTLD'; testnum = 9;END;
           ELSE IF FATEST = 'Mean Largest and Perpendicular Diameters' THEN DO; new_test = 'MLAPD'; testnum = 10;END;
     WHERE  AVALC NE '**' ;
     KEEP SASR USUBJID PARAMCD PARAM AVALC AVISITN ADT FATEST new_test FADTL &treat_var. new_FALAT testnum nlat new_avalc;
RUN;

PROC SORT DATA= adfapr_2 OUT = adfapr_3 NODUPKEY ;
    BY SASR USUBJID AVISITN ADT FADTL &treat_var. new_FALAT testnum  ;
RUN;

PROC TRANSPOSE DATA = adfapr_3 OUT = adfapr_4 (DROP=_name_ );
     BY SASR USUBJID AVISITN ADT FADTL &treat_var. new_FALAT ;
     ID new_test ;
     VAR new_avalc ;
     WHERE NOT missing(new_test);
RUN;

DATA adfapr_final;
     SET adfapr_4;
    LABEL AVISITN = 'Visit'
          SASR = 'Subject# Identifier/# Age/# Sex/# Race'
          FADTL = 'Measurement # Date'
          new_FALAT = 'Laterality'
          OV = 'Ovary#Visualized'
          OLD = 'Ovary#largest#diameter(mm)'
          ODPLD = 'Ovary diameter#perpendicular to # largest diameter (mm) '
          CLSV = 'Cyst like#structure#visualized'
          TOCS = 'Type of # Cyst like # strucutre'
          FLSD = 'Follicle-Like # Struct. # Demonstr.'
          EORF = 'Evidence # of ruptured # follicle'
          LD = 'Cyst like # structure # largest # diameter (mm)'
          DPTLD = 'Diameter # perpendicular to # largest # diameter (mm)'
          MLAPD = 'Mean # largest # and # perpendicular # diameters (mm)'
          &treat_var. = 'Actual Treatment Group';
RUN;

PROC SORT DATA= adfapr_final;
     BY &treat_var. &subj_var.  AVISITN new_FALAT;
RUN;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%MTITLE;

%datalist(
    data     = adfapr_final
  , page     = &treat_var.
  , by       = SASR AVISITN FADTL new_FALAT
  , var      = OV OLD ODPLD CLSV TOCS FLSD EORF LD DPTLD MLAPD
  , optimal  = y
  , maxlen   = 2
  , space    = 1
  , split    =
  , hsplit   = #
  , layout   = Standard
  , bylen    = 3
  , hc_align = CENTER
  , hn_align = CENTER
);

%endprog();