/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_1_6_adcm_sbj_psttrtmed);
/*
 * Purpose          : Post treatment medication: number of subjects (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : enpjp (Prashant Patel) / date: 27OCT2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_1_6_adcm_sbj_psttrtmed.sas (enpjp (Prashant Patel) / date: 09SEP2023)
 ******************************************************************************/

** >>> START: Create table - Medication started after stop of study treatment: number of subjects <<population>>;
%MACRO by_population(pop=);

**get data and select only relevant population;
%load_ads_dat(
    adcm_view
  , adsDomain = adcm
  , where     = CMCAT = 'PRIOR AND CONCOMITANT MEDICATION' and CONFL ne 'Y' and FUPFL = 'Y'
  , adslWhere = &&&pop._cond.
  , view      = N
);

%extend_data(indat = adcm_view, outdat = adcm)

**create one observation per class/subclass;
DATA atc;
    SET adcm_view;
    ARRAY c1 cmcl:;
    ARRAY c2 cmscl:;
    ATTRIB CLASS    LENGTH=$1 FORMAT=$atc. LABEL='ATC CLASS'
           SUBCLASS LENGTH=$3 FORMAT=$atc. LABEL='ATC SUBCLASS';
    DO i = 1 TO dim(c1);
        IF NOT missing(c1{i}) THEN DO;
            CLASS = c1{i};
            SUBCLASS = c2{i};
            OUTPUT;
        END;
    END;
RUN;


%mtitle;
%incidence_print(
    data        = atc
  , data_n      = ads.adsl(where=(&&&pop._cond.))
  , var         = class subclass
  , class       = &treat_arm_a.
  , triggercond = cmdecod ne ' '
  , total       = yes
  , sortorder   = FREQA
  , evlabel     = ATC CLASS#   SUBCLASS#      WHO-DD Version &v_whodd.
  , anytxt      = Number (%) of subjects who took at least one medication that started after stop of study treatment
  , uncodedtxt  = DRUG WITH NO SUBCLASS DEFINED
  , maxlen      = 100
  , hsplit      = '@#'
)
%MEND;

**safety analysis set;
%by_population(pop=saf);
** <<< END: Create table - Medication started after stop of study treatment: number of subjects <<population>>;


**Use %endprog at the end of each study program;
%endprog();



