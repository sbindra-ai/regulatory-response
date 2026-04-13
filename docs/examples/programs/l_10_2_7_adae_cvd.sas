/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_7_adae_cvd);
/*
 * Purpose          : subjects with COVID-19 adverse event
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 17OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_7_adae_cvd.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/

%m_create_ads_view(
    adsDomain = adae
  , outDat    = adaeall
  , adslVars  = INVNAM COUNTRY SAFFL SASR UASR ETHNIC TRT01AN TRTSDT
)

%extend_data(indat = adaeall, outdat = adae)

********************<  creating listing dates  ***********************;

DATA adaeall_1;
    SET adae;
    IF ASTDT =< TRTSDT THEN PREFL_new = 'YES' ;
    ELSE IF ASTDT > TRTSDT THEN PREFL_new = 'NO' ;
    WHERE AEEPRELI = "Y"
          and &saf_cond;
RUN;

%m_create_dtl(inputds=adaeall_1, varname= AEENDTL);
%m_create_dtl(inputds=adaeall_1, varname= AESTDTL);

*********************< creating listing variable **************************;

DATA adae_covid;
    ATTRIB SASR_ethnic FORMAT =$200. LABEL ='Subject Identifier/#Age/ Sex/ Race / Ethnicity';
    ATTRIB TERMS FORMAT=$200. LABEL="Preferred #Term/#Reported #Term";
    ATTRIB SERIOUS FORMAT=$200. LABEL="Serious/#Reason";
    ATTRIB DATES FORMAT=$200. LABEL="Start/#End #(Relative Day)";
    ATTRIB REL_PROC FORMAT =$200. LABEL ="Relation#to Study# Drug/#Protocol#Required#Procedure";
    ATTRIB INVNAM LABEL ='Investigator' ;
    ATTRIB AESEV       LABEL ='Severity/ Intensity';
SET adaeall_1;
    LABEL TRT01AN  = 'Actual Treatment Group'
          SASR = 'Subject Identifier/# Age/ Sex/ Race'
          AECONTRT = "Concomitant#or Additional#Treatment#Given"
          PREFL_new  = 'Start#Prior#to Study# Drug  '
          AESTDTL = 'Start#Date of#Adverse#Event'
          AEENDTL = 'End #Date of#Adverse#Event'
          ADURN   = 'Adverse#Event#Duration# (Days)'
          AEACN = "Action#Taken#With#Study#Drug"
          AEACNOTH = "Other#Specific#Treatment of#Adverse #Event"
          AEOUT = "Outcome #of#Adverse#Event"
          COUNTRY = 'Country/#Region'
          AECONTRT_new = 'Concomitant or Additional Treatment Give';
    IF ARELN = 1 THEN AREL ='YES'; ELSE IF ARELN = 0 THEN AREL = 'NO' ;
          SASR_ETHNIC = strip(SASR)||"/"||strip(ETHNIC);                            *<creating variable UASR/Ethnicity*;
          TERMS = strip(AEDECOD) ||"/"||strip(AETERM);                              *<concatenating Preferred Term and Reported Term *;
          DATES =cat(ASTDY,'/', AENDY);                                             *<concatenating Analysis start day and end day *;
          REL_PROC =strip(upcase(AREL)) ||"/"||strip(upcase(put( AERELPR,$x_ny.)));
          AECONTRT_new = strip(upcase(put(AECONTRT, $x_ny.)));
    IF missing (AESREAS) THEN SERIOUS = upcase(strip(put(AESER, $x_ny.)));          *<as AESER is = NO so reason is missing - it shows only serious*;
                         ELSE  SERIOUS =upcase( strip(put(AESER,$x_ny.))||"/"||strip(AESREAS));
RUN;


*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;


%MTITLE;

%datalist(
    data     = adae_covid
  , page     = &treat_var.
  , by       = COUNTRY INVNAM SASR_ETHNIC
  , var      = TERMS PREFL_new SERIOUS AESTDTL AEENDTL dates ADURN AESEV REL_PROC AEACN AEACNOTH AEOUT AECONTRT_new
  , optimal  = Y
  , maxlen   = 4
  , space    = 1
  , split    = '/*'
  , hsplit   = #
  , layout   = Standard
  , bylen    = 4
  , hc_align = CENTER
  , hn_align = CENTER
);

%endprog();