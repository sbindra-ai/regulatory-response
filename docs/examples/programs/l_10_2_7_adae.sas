/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_7_adae);
/*
 * Purpose          : Adverse events
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 17OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_7_adae.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/

%m_create_ads_view(adsDomain = adae, outDat = adaeall)

%extend_data(indat = adaeall, outdat = adae)

********************<  creating listing dates  ***********************;
DATA adaeall_1;
    SET adae;
    where &saf_cond;
RUN;

%m_create_dtl(inputds=adaeall_1, varname= AEENDTL);
%m_create_dtl(inputds=adaeall_1, varname= AESTDTL);

*********************< creating listing variable **************************;

DATA adae_1;
    ATTRIB TERMS       FORMAT=$200.   LABEL="Preferred #Term /#Reported #Term";
    ATTRIB SERIOUS     FORMAT=$400.   LABEL="Serious/#Reason";
    ATTRIB DATES       FORMAT=$15.    LABEL="Start/End #(Relative Day)";
    ATTRIB REL_PROC    FORMAT =$200.  LABEL ="Relation #to Study# Drug /#Protocol#Required#Procedure";
    ATTRIB AESEV      LABEL ='Severity/ Intensity';
SET adaeall_1;
    LABEL TRT01AN     = 'Actual Treatment Group'
          SASR = 'Subject Identifier/# Age/ Sex/ Race'
          ADUR     = 'Duration of AE (Days)'
          AESTDTL = 'Start Date/# Time of AE'
          AEENDTL = 'End Date/# Time of AE'
          AEACN    = "Action Taken With Study Treatment"
          AEOUT    = "Outcome of AE"
          AEACNOTH = 'Other Action(s) Taken'
          AECONTRT_1 = 'Remedial Drug Therapy';
    IF ARELN = 1 THEN AREL ='YES'; ELSE IF ARELN = 0 THEN AREL = 'NO' ;
    TERMS      = strip(AEDECOD) ||"/"||strip(AETERM );
    DATES      = cat (ASTDY,'/', AENDY);
    REL_PROC   = strip(upcase(AREL))||"/"||strip(upcase(put(AERELPR, x_ny.)));
    AECONTRT_1 = upcase(put(AECONTRT, $x_ny.));
    ADUR       = put(ADURN, best.);
    IF missing (AESREAS) THEN SERIOUS = strip(upcase(put(AESER , $x_ny.))) ;
                         ELSE  SERIOUS = strip(upcase(put(AESER , $x_ny.))||"/"||strip(upcase(AESREAS)));
RUN;


PROC SORT DATA = adae_1 OUT= adae_final;
    BY &treat_var. &subj_var. ASTDY AESEQ ;
RUN;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;


%MTITLE;

%datalist(
    data     = adae_final
  , page     = &treat_var.
  , by       = SASR
  , var      = TERMS SERIOUS AESTDTL AEENDTL DATES ADUR AESEV REL_PROC AEACN AEOUT AECONTRT_1 AEACNOTH
  , order    = AESEQ
  , freeline = SASR
  , optimal  = Y
  , maxlen   = 3
  , space    = 1
  , split    = '/*'
  , hsplit   = #
  , layout   = Standard
  , bylen    = 3
  , hc_align = CENTER
  , hn_align = CENTER
);

%endprog();