/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_3_7_adfapr_endo_sbase);
/*
 * Purpose          : Endometrial thickness: summary statistics and change from baseline by treatment group  (SAF)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : epjgw (Roland Meizis) / date: 12DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/val/analysis/pgms/t_8_3_7_adfapr_endo_sbase.sas (egavb (Reema S Pawar) / date: 17JUN2023)
 ******************************************************************************/

%load_ads_dat(
    adfapr_view
  , adsDomain = adfapr
  , where     = PARCAT2 EQ 'ULTRASOUND UTERUS'
                   AND ANL01FL = 'Y'
                   AND  paramcd EQ 'ENDTHCK'
  , adslWhere = &saf_cond
)
%load_ads_dat(
    mh_hys_view
  , adsDomain = admh
  , where     = mhdecod IN ('Hysterectomy' 'Hysterosalpingectomy' 'Hysterosalpingo-oophorectomy' 'Radical hysterectomy') /* hysterectomy subjects */
  , adslWhere = &saf_cond
)

**************************  %extend_data ***************************;

%extend_data(indat = adfapr_view, outdat = adfapr)
%extend_data(indat = mh_hys_view, outdat = mh_hys)


**************************  removing hysterectomy subjects  *****************;

PROC SQL;
    CREATE TABLE adfapr_thick AS
           SELECT *  FROM adfapr
           WHERE USUBJID NOT IN (SELECT USUBJID FROM mh_hys);
QUIT;

/* Change treatment label */
data adfapr_thick;
    set adfapr_thick;

    attrib &treat_var. label="Treatment";
run;

%MTITLE;

%desc_tab(
    data         = adfapr_thick
  , var          = aval
  , stat         = n mean std min median max
  , class        = Avisitn
  , total        = NO
  , round_factor = 0.1
  , vlabel       = no
  , baseline     = ablfl = "Y"
  , compare_var  = chg
  , time         = &treat_var
  , visittext    = visit
  , baselinetext = baseline at visit
  , subject      = subjid
  , optimal      = yes
  , freeline     =
);

/* Use %endprog at the end of each study program */
%endprog;