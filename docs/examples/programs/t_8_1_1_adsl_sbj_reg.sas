/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_1_1_adsl_sbj_reg);
/*
 * Purpose          : Number of subjects by pooled region and country/ region (all randomized subjects)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : enpjp (Prashant Patel) / date: 12SEP2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_1_1_adsl_sbj_reg.sas (enpjp (Prashant Patel) / date: 09SEP2023)
 ******************************************************************************/

%load_ads_dat(adsl_view, adsDomain = adsl, where = &RAND_COND. );

%extend_data(indat = adsl_view, outdat = adsl)

PROC SQL;
    CREATE TABLE adslfinal AS
      SELECT l.*, r.descrip AS countryc LABEL='Country/Region'
      FROM adsl_view AS l LEFT JOIN codelist.country AS r ON l.country=r.start;
QUIT;

data adslfinal;
    set adslfinal;
    countryc = propcase(countryc);
RUN;

%mtitle;
%freq_tab(
    data         = adslfinal
  , data_n       = adsl_view
  , var          = countryc
  , subject      = usubjid
  , by           = region1n
  , totalby      = region1n
  , totaltxt     = %str(All)
  , class        = &TREAT_ARM_P
  , hlabel       = YES
  , subjectlabel = Total
  , complete     = MIN
)


/* Use %endprog at the end of each study program */
%endprog();

