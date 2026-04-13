/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = f_8_1_7_tte_dis_km  );
/*
 * Purpose          : Kaplan-Meier-Plot of the time from randomization to permanent discontinuation of
 *                    randomized treatment (FAS)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gnrty (Ashu Pandey) / date: 04DEC2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/f_8_1_7_tte_dis_km.sas (emvsx (Phani Tata) / date: 18SEP2023)
 ******************************************************************************/

PROC SORT DATA=ads.adsl  OUT = adsl (KEEP = usubjid trt01pn );
  BY usubjid    ;
  WHERE  fasfl = "Y";
RUN;

PROC SORT DATA=ads.adtte OUT = adtte ;
  BY usubjid   ;
  WHERE paramcd = "T2DISC";
RUN;

DATA adtte ;
    MERGE adtte (IN = a )
          adsl ;
    BY usubjid ;
    IF a ;
RUN;


PROC SORT DATA=   adtte ;
  BY  paramcd trt01pn   ;
RUN;


PROC LIFETEST data= adtte  alphaqt=0.05 method=km outsurv=km_outsurv1 conftype=linear stderr;
    TIME aval * cnsr(1);
    STRATA trt01pn ;
    ODS OUTPUT ProductLimitEstimates=kme_sd1;
RUN;

%MTITLE;

%KaplanMeierPlot(
    data       = km_outsurv1
  , class      = trt01pn
  , atriskdata = kme_sd1
  , filename   = f_8_1_7_tte_dis_km
  , xlabel     = Weeks
  , ylabel     = Probability of no event
  , legendtitle = Treatment Group
  , title_ny    = NO

);

*----------------------------------*;
%endprog;
