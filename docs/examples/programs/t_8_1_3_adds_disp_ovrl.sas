/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
  %iniprog(name = t_8_1_3_adds_disp_ovrl);
/*
 * Purpose          : Disposition in overall study (all enrolled subjects)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : enpjp (Prashant Patel) / date: 20DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_1_3_adds_disp_ovrl_adhoc.sas (enpjp (Prashant Patel) / date: 05DEC2023)
 ******************************************************************************/



** >>> START: Create table - Disposition in overall study <<population>>;
%MACRO by_population(pop=);

**get data and select only relevant population;
%load_ads_dat(
    adsl_view
  , adsDomain = adsl
  , where     = &&&pop._cond.
);

%extend_data(indat = adsl_view, outdat = adsl)


data fup;
    set ADS.ADDS (where = (dscat eq "DISPOSITION EVENT" and dsscat ne "INFORMED CONSENT" and epoch  in ("FOLLOW-UP" "POST-TREATMENT")));
    keep usubjid fup;
    fup=1;
RUN;

 data disc;
     set ADS.ADDS (where = (dscat eq "DISPOSITION EVENT" and dsscat ne "INFORMED CONSENT" and dssubdec = "STOP REGULAR SCHEDULED CONTACT" and epoch="TREATMENT" and dsscat ne "INFORMED CONSENT"));
     keep usubjid disc;
     disc=1;
 RUN;


data trtcomp;
    set ADS.ADDS (where = (dscat eq "DISPOSITION EVENT" and dsscat ne "INFORMED CONSENT" and dsdecod = "COMPLETED" and epoch="TREATMENT" and dsscat ne "INFORMED CONSENT"));
    keep usubjid trtcomp;
    trtcomp=1;
RUN;

data FINAL;
    merge adsl_view(in=a) fup(in=b) trtcomp(in=c) disc(in=d);
    by usubjid;
    if a;
    if not b and not d then fup=0;

    if not b and d then fup=-1;
    if not c then trtcomp=0;
    %M_PropIt(Var=dcsreas);
RUN;

/**//**** Handling of subjects who never came for post treatment discontinuation follow up  *******/
/**/
/**/
/*data final;*/
/*    set final;*/
/*    if complfl  = "N" and dcsreas eq " " and fup=0 then do;*/
/*        dcsreas_prop = 'Missing^&super_a.' ;*/
/*    END;*/
/*RUN;*/

%mtitle;
%disposition(
    data            = FINAL
  , class           = trt01pn
  , groups          = 'enrlfl   = "Y"'             * 'Enrolled'
                      'randfl   = "Y"'             * 'Randomized'
                      'exnyovln = 1'               * 'Treated'
                      'complfl  = "Y"'             * 'Completed study'
                      'complfl  = "N" and dcsreas_prop eq " "  and fup=1'             * 'Did not complete study treatment but completed post-treatment phase/follow-up'

  , groupstxt       = Number of subjects
  , discontinued    = (complfl  = "N" and dcsreas ne " ") or  (complfl  = "N" and dcsreas_prop eq " " and fup=0)
  , discontinuedtxt = Did not complete study
  , reason          = dcsreas_prop
  , code99x         = NO
  , freeline        =
)

%MEND;

**all enrolled subjects;
%by_population(pop=enr);
** <<< END: Create table - Disposition in overall study <<population>>;

**Use %endprog at the end of each study program;
%endprog;