/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = l_10_2_7_adae_tesae);
/*
 * Purpose          : Treatment-emergent serious adverse events
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : egavb (Reema S Pawar) / date: 19OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/l_10_2_7_adae_tesae.sas (egavb (Reema S Pawar) / date: 13JUN2023)
 ******************************************************************************/

%m_create_ads_view(adsDomain = adae, outDat = adaeall)

%extend_data(indat = adaeall, outdat = adae)

**********************<  creating listing dates  *****************************;

DATA adaeall_1;
    SET adae;
    WHERE TRTEMFL = 'Y'
          AND AESER ='Y'
          and &saf_cond;
RUN;

%m_create_dtl(inputds=adaeall_1, varname= AESTDTL);
%m_create_dtl(inputds=adaeall_1, varname= AEENDTL);

************************<  creating listing variable  ************************;

DATA ae_final;
    ATTRIB TERMS       FORMAT=$200.    LABEL="Primary SOC#/Preferred #Term#/Reported #Term";
    ATTRIB SERIOUS     FORMAT=$400.    LABEL="Serious/#Reason";
    ATTRIB ST_DATES    FORMAT=$20.     LABEL="Onset Date/ Start/ Stop (Relative to Treatment)";
    ATTRIB ED_DATES    FORMAT=$20.     LABEL="Stop Date/ Start/ Stop (Relative to Treatment)";
    ATTRIB REL_PROC    FORMAT =$200.   LABEL ="Relation #to Study# Drug /#Protocol#Required#Procedure";
    ATTRIB AESEV        LABEL ='Severity/ Intensity';
    ATTRIB SASRE       LABEL ='Subject Identifier/# Age/ Sex/# Race/# Ethnicity';
    SET adaeall_1;
    SASRE   = strip(SASR)||'/'||strip(ETHNIC);
    TERMS   = strip(AEBODSYS)||"/"||strip(AEDECOD) ||"/"||strip(AETERM );
    IF missing (AESREAS) THEN SERIOUS = strip(upcase(put(AESER , $x_ny.))) ;
                         ELSE  SERIOUS = strip(upcase(put(AESER , $x_ny.))||"/"||strip(upcase(AESREAS)));
    ST_DATES      = strip(AESTDTL)||'/'||strip(put(ASTDY, best.))||'/'||strip(put(AENDY, best.));
    ED_DATES      = strip(AEENDTL)||'/'||strip(put(ASTDY, best.))||'/'||strip(put(AENDY, best.));
    REL_PROC   = strip(upcase(put(AREL, $x_ny.)))||"/"||strip(upcase(put(AERELPR, $x_ny.)));
    IF NOT missing(AECONTRT) THEN DO AECONTRT_1 = upcase(put(AECONTRT, $x_ny.))||'/'||AEACNOTH;END;
    ADUR       = put(ADURN, best.);
    LABEL AESREAS     = 'Reason(s) for Seriousness'
          ADUR        = 'Duration (Days)'
          AEACN       = "Action Taken"
          AECONTRT_1  = 'Remedial Drug Therapy/ Other Specific Action(s) of Adverse Event'
          AEOUT       = "Outcome"
          &treat_var. = "Actual Treatment Group";
RUN;

PROC SORT DATA = ae_final ;
    BY SASR AESEQ ;
RUN;

*<*****************************************************************************;
*< create listing                                                              ;
*<*****************************************************************************;

%MTITLE;

%datalist(
    data     = ae_final
  , page     = &treat_var.
  , by       = SASRE
  , var      = TERMS AESEV REL_PROC AESREAS ST_DATES ED_DATES ADUR AEACN AECONTRT_1 AEOUT
  , order    = AESEQ
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