/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_8_2_adlb_liv_hp);
/*
 * Purpose          : Subjects meeting lab elevation criteria for hepatic safety - subject listing on lab parameters (SAF)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gniiq (Mayur Parchure) / date: 21FEB2024
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/l_10_2_8_2_adlb_liv_hp.sas (gniiq (Mayur Parchure) / date: 18OCT2023)
 ******************************************************************************/
*PARAM used for Liver Monitoring *;
*SGPT - Alanine Aminotransferase (U/L) in Serum or Plasma ALT
*ALKPHOSP - Alkaline Phosphatase (U/L) in Serum or Plasma ALP
* - Aspartate Aminotransferase (U/L) in Serum or Plasma AST
*BILITOSP - Bilirubin (mg/dL) in Serum or Plasma
*;

%load_ads_dat(
    adlb_view
  , adsDomain = adlb
  , where     = paramcd in (  'SGOTSP'  'SGPTSP' 'BILITOSP' 'ALKPHOSP'  'PTINR' 'BILIDISP' 'CKSP' 'GGT' 'LDH')
)

%extend_data(indat = adlb_view , outdat = adlb )

PROC SQL NOPRINT;
    CREATE TABLE ce2 AS
    SELECT DISTINCT USUBJID FROM sp.ce ;
    CREATE TABLE adlb3 AS
    SELECT a.* FROM adlb_view AS a INNER JOIN ce2 AS b
    ON a.USUBJID=b.USUBJID
    ;
QUIT;

DATA adlb4;
    SET adlb3(where=(~missing(aval)));
    LENGTH RESULTC $30.;
    IF ~missing(TRTSDT) THEN std= put(TRTSDT,date9.);
    ELSE std='';
    IF ~missing(TRTEDT) THEN edt= put(TRTEDT,date9.);
    ELSE edt='';
    STD_EDT= strip(std) ||"/ "|| strip(edt);

    IF ~missing(ADT) THEN ADT1= put(ADT,date9.);

    IF ~missing(aval) AND ~missing(ANRHI) and
       PARAMCD ne 'PTINR' THEN DO;
        RESULT=aval/ANRHI;
 /*   else RESULT=aval;*/
    RESULTC=catx('; ',put(result,5.3),aval);
       END;
     ELSE IF ~missing(aval) AND ~missing(ANRHI) and
         PARAMCD eq 'PTINR' THEN DO;
             RESULT=aval;
             RESULTC=strip(put(result,4.2));
         END;

    ADY1=strip(ADT1) ||"/ "||strip(put(ADY,best.));
    VISIT= strip(put(AVISITN, Z_AVISIT.));
    LABEL STD_EDT = "First/ Last#study drug#administration"
          VISIT="Visit"
          ADY1 = "Visit date/#Study day";
RUN;

DATA adlb4;
    SET adlb4;
    FORMAT _all_;
RUN;


PROC SORT DATA=adlb4 OUT=adlb5;
    BY &treat_var. USUBJID SASR STD_EDT ADT ADY ADY1 visit PARAMCD;
RUN;

PROC TRANSPOSE DATA=adlb5 OUT=adlb6;
    BY &treat_var. USUBJID SASR STD_EDT ADT ADY ADY1 visit ;
    VAR RESULTC;
    ID PARAMCD;
RUN;


DATA adlb_fin;
    SET adlb6;
    BY &treat_var. USUBJID SASR STD_EDT ADT ADY ADY1 VISIT;

format &treat_var. Z_TRT.;

    LABEL &treat_var. = 'Actual Treatment Group'
        SASR = 'Subject identifier#/Age/Sex#/Race'
        SGPTSP= 'ALT#(relative to#ULN;#U/L)'
        SGOTSP= 'AST#(relative to#ULN;#U/L)'
        BILITOSP = 'Total Bilirubin#(relative to#ULN;#mg/dL)'
        ALKPHOSP = 'ALP#(relative to#ULN;#U/L)'
        PTINR = 'INR'
        GGT =  "GGT#(relative to#ULN;#U/L)"
        BILIDISP = "DB#(relative to#ULN;#mg/dL)"
        CKSP =  "CK#(relative to#ULN;#U/L)"
        LDH =  "LDH#(relative to#ULN;#U/L)"
        ;
RUN;

%MTITLE;

%datalist(
    data     = adlb_fin
  , page     = &treat_var.
  , by       = SASR STD_EDT ADT ADY1 VISIT
  , var      = SGPTSP SGOTSP BILITOSP ALKPHOSP PTINR GGT BILIDISP CKSP LDH
  , order    = ADT VISIT
  , freeline = SASR
  , maxlen   = 28
  , space    = 1
  , hsplit   = "#"
  , bylen    = 12
)

%endprog()