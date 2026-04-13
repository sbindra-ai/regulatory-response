/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_1_1_addv_pdsf_tunt);
/*
 * Purpose          : Protocol deviations and screen failures by {trial unit}
 * Programming Spec :
 * Validation Level : 2 - Verification by Double Programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : enpjp (Prashant Patel) / date: 12SEP2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_1_1_addv_pdsf_tunt.sas (enpjp (Prashant Patel) / date: 09SEP2023)
 ******************************************************************************/

**get ADSL;
%load_ads_dat(adsl_view, adsDomain = adsl, where = &ENR_COND., view = N);
PROC SORT DATA=adsl_view;BY &subj_var.;RUN;

**select only records judged as important deviations;
%load_ads_dat(addv_imp, adsDomain = addv, where = idreqimd ne ".", adslWhere = &ENR_COND., keep = &subj_var. DVCAT, view = N);
PROC SORT DATA=addv_imp(KEEP=&subj_var. dvcat) NODUPKEY;BY &subj_var.;RUN;

%extend_data(indat = adsl_view, outdat = adsl)
%extend_data(indat = addv_imp, outdat = addv)

DATA addv_adsl_;
    MERGE addv_imp adsl_view;
    BY &subj_var.;
    format country _country.;
RUN;

PROC SQL;
    CREATE TABLE addv_adsl AS
      SELECT l.*, r.descrip AS countryc LABEL='Country/Region'
      FROM addv_adsl_ AS l LEFT JOIN codelist.country AS r ON l.country=r.start;
QUIT;

data addv_adsl;
    set addv_adsl;
    countryc = propcase(countryc);
RUN;

%mtitle;
%dispositionpss(
    data      = addv_adsl
  , by        = region1n countryc siteid
  , class     =
  , groups    = 'enrlfl = "Y"'                                * 'Number of Enrolled Subjects'
                'scrnflfl = "Y"'                              * 'Number of Screening Failures'
  , groupspct = yes
  , enrolled  = no
  , totalby   = region1n
  , outdat    = out1
);


%dispositionpss(
    data      = addv_adsl
  , by        = region1n countryc siteid
  , class     = &TREAT_ARM_P
  , groups    =  'randfl = "Y"'                                * 'Number of Subjects Randomized to Treatment'
                 'dvcat = "FINDING" and randfl = "Y"'        * 'Number of Subjects with Important Protocol Deviations'
  , groupspct = yes
  , enrolled  = no
  , totalby   = region1n
  , outdat    = out
);

proc sort data = out;
    by region1n countryc siteid  _freeline _trttot  _cl_ord;
RUN;

proc sort data = out1;
    by region1n countryc siteid  _freeline _trttot  ;
RUN;

DATA out2;
    merge out(rename = (_group1c=_group3c _group2c=_group4c _group1=_group3 _group2=_group4)) out1(keep = region1n countryc siteid _freeline _trttot   _group1 _group2c);
    by region1n countryc siteid _freeline _trttot  ;
    IF &TREAT_ARM_P ne 99999999 /*Total*/ THEN call missing(of _group1-_group2);
    IF not missing(&TREAT_ARM_P);
RUN;

DATA outinp2;
    SET outinp;
    IF keyword = 'DATA' THEN value = 'out2';
    IF keyword = 'BY' THEN value = tranwrd(value,"&TREAT_ARM_P",'');
    IF keyword = 'VAR' THEN value = tranwrd(value,'_group1c _group2c',"_group1 _group2c &TREAT_ARM_P _group3c _group4c");
RUN;

%let _miss = %sysfunc(getoption(missing));
option missing=' ';
%mosto_param_from_dat(data=outinp2, var=g_call);
%datalist(&g_call);
option missing="&_miss";

**Use %endprog at the end of each study program;
%endprog;


