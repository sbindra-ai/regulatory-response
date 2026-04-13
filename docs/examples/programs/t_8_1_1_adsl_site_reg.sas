/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_1_1_adsl_site_reg);
/*
 * Purpose          : Number of sites by pooled region and country/ region (all randomized subjects)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : enpjp (Prashant Patel) / date: 12SEP2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_1_1_adsl_site_reg.sas (enpjp (Prashant Patel) / date: 09SEP2023)
 ******************************************************************************/

%load_ads_dat(adsl_view, adsDomain = adsl, adslVars = , view = N);

%extend_data(indat = adsl_view, outdat = adsl)

** >>> START: Create table - Number of sites by pooled region and country/region <<population>>;
%MACRO by_population(pop=);

/* select only relevant population */
DATA adsl_;
    SET adsl_view  (where = (&&&pop._cond.));
    _temp_site='Study Sites';
RUN;

** get labels for Country/Region;
PROC SQL;
    CREATE TABLE adsl1_ AS
      SELECT l.*, r.descrip AS countryc LABEL='Country/Region'
      FROM adsl_ AS l LEFT JOIN codelist.country AS r ON l.country=r.start;
QUIT;

data adsl1_;
    set adsl1_;
    countryc = propcase(countryc);
RUN;

%mtitle
%freq_tab(
    data         = adsl1_
  , data_n       = adsl1_
  , var          = countryc
  , subject      = siteid /*Note: count number of study sites, not subjects!*/
  , by           = region1n
  , total        = NO
  , totalby      = region1n
  , totaltxt     = All
  , class        = _temp_site
  , hlabel       = "Country/Region"
  , subjectlabel = Total
  , complete     = MIN
  , optimal      = YES
  , hb_align     = LEFT
  , hv_align     = LEFT
  , freeline     = region1n
)

%MEND by_population;

**all randomized subjects;
%by_population(pop=rand);


/* Use %endprog at the end of each study program */
%endprog();