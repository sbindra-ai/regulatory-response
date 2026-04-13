/*******************************************************************************
 * Bayer AG
 * Study            : 21651 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_8_1_5_adrp_rpmens_hist);
/*
 * Purpose          : Custom table: Reproductive and menstrual history <<subgroup>> (safety analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : enpjp (Prashant Patel) / date: 12SEP2023
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/main01/dev/analysis/pgms/t_8_1_5_adrp_rpmens_hist.sas (enpjp (Prashant Patel) / date: 09SEP2023)
 ******************************************************************************/

%macro rpt(pop=, trt=, poplabel=);

%load_ads_dat(adrp_view1, adsDomain = adrp, adslWhere = &pop.)
%load_ads_dat(adsl_view, adsDomain = adsl, where = &pop., adslVars =);
%load_ads_dat(admh_view, adsDomain = admh, adslWhere = &pop., adslVars  =);

%extend_data(indat = adrp_view1, outdat = adrp1)
%extend_data(indat = adsl_view, outdat = adslh)
%extend_data(indat = admh_view, outdat = admh)

/*hysterectomy & oophorectomy */
proc sort data = admh_view out=mh1(keep = usubjid) nodupkey;
    by usubjid ;
    where mhdecod in ('Hysterectomy' 'Hysterosalpingectomy' 'Hysterosalpingo-oophorectomy' 'Radical hysterectomy');
RUN;

proc sort data = admh_view out=mh2(keep = usubjid) nodupkey;
    by usubjid ;
    where mhdecod in ('Hysterosalpingo-oophorectomy' 'Oophorectomy' 'Oophorectomy bilateral' 'Salpingo-oophorectomy' 'Salpingo-oophorectomy bilateral' 'Salpingo-oophorectomy unilateral');
RUN;

data adrp_view;
    set adrp_view1;
    param = put(paramcd,$X_rppar.);
RUN;

/*Transpose data for the table output*/
proc transpose data = adrp_view out = adrp_tran;
    by usubjid &trt.;
    var aval;
    id paramcd;
    idlabel param;
    format paramcd;
RUN;

ods escapechar="^";

data adrp_tran1;
    merge adsl_view(in=sl)  adrp_tran(in=a) mh1(in=b) mh2(in=c);
    by usubjid;
    if sl;
    if b then hys=1;
    else hys =0;
    if c then os=1;
    else os =0;
    brthc=brthn;*compress(input(brthn,best.));
    pregnc=pregnn;*compress(input(pregnn,best.));
    label amenlen = "Duration of being amenorrheic (years)" ;
    label brthc = "Number of births" ;
    label pregnc = "Number of pregnancies" ;
    label brthn = "Number of births" ;
    label pregnn = "Number of pregnancies" ;
    label hys = "Hysterectomy^&super_a";
    label os = "Oophorectomy^&super_b";
    format hys os _ny. pregnn brthn 8. amenlen 8.1 pregnc brthc 2.;
RUN;

%mtitle;
%desc_freq_tab(
    data         = adrp_tran1
  , var          = pregnn pregnc brthn brthc amenlen hys os
  , class        = &trt.
  , var_freq     = pregnc brthc hys os
  , data_n       = adsl_view
  , subject      = usubjid
  , basepct      = N_CLASS
  , space        = 1
)

%MEND;

%rpt(pop=%str(&FAS_COND), trt=&TREAT_ARM_P, poplabel=&FAS_LABEL);
%rpt(pop=%str(&SAF_COND), trt=&TREAT_ARM_A, poplabel=&SAF_LABEL);
%rpt(pop=%str(&SLAS_COND), trt=&TREAT_ARM_P, poplabel=&SLAS_LABEL);

%endprog();