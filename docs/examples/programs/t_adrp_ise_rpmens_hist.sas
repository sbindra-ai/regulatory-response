/*******************************************************************************
 * Bayer AG
 * Study            :
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adrp_ise_rpmens_hist);
/*
 * Purpose          : Reproductive and menstrual history (full analysis set)
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : gdcpl (Derek Li) / date: 08DEC2023
 * Reference prog   :
 ******************************************************************************/


%LET mosto_param_class = &mosto_param_class_eff.;

%load_ads_dat(adsl_view, adsDomain = adsl);
%load_ads_dat(adrp_view, adsDomain = adrp)
%load_ads_dat(admh_view, adsDomain = admh);

%extend_data(
    indat       = adsl_view
  , outdat      = adsl_ext
  , var         = &extend_var_disp_eff.
  , extend_rule = &extend_rule_disp_eff.
);

%extend_data(
    indat       = adrp_view
  , outdat      = adrp_ext
  , var         = &extend_var_disp_eff.
  , extend_rule = &extend_rule_disp_eff.
);

%extend_data(
    indat       = admh_view
  , outdat      = admh_ext
  , var         = &extend_var_disp_eff.
  , extend_rule = &extend_rule_disp_eff.
);

** Steps to transpose ADRP parameters;
data adrp_ext;
    set adrp_ext;
    ATTRIB param LENGTH = $200;
    param = VVALUE(paramcd);
RUN;
proc sort data=adrp_ext; by &subj_var.; RUN;

proc transpose data = adrp_ext out = adrp_ext_trans;
    by &subj_var.;
    var aval;
    id paramcd;
    idlabel param;
    format paramcd;
RUN;

DATA adrp_ext_trans;
    SET adrp_ext_trans;

    FORMAT pregnn brthn 8. amenlen 8.1 pregnc brthc 2.;

    ATTRIB amenlen  LABEL = "Duration of being amenorrheic (years)";
    ATTRIB brthc    LABEL = "Number of births";
    ATTRIB pregnc   LABEL = "Number of pregnancies";
    LABEL brthn = "Number of births" ;
    LABEL pregnn = "Number of pregnancies" ;
    brthc  = brthn;
    pregnc = pregnn;
RUN;

** Derive Hysterectomy;
DATA hysterectomy(KEEP=&subj_var. hys);
    SET admh_ext(where= (mhdecod in ('Hysterectomy' 'Hysterosalpingectomy' 'Hysterosalpingo-oophorectomy' 'Radical hysterectomy')));
    ATTRIB hys LABEL = "Hysterectomy*" FORMAT = ny.;
    hys = 1;
RUN;
PROC SORT DATA=hysterectomy NODUPKEY; BY &subj_var.; RUN;

** Derive Oophorectomy;
DATA oophorectomy(KEEP=&subj_var. os);
    SET admh_ext(where= (mhdecod in ('Hysterosalpingo-oophorectomy' 'Oophorectomy' 'Oophorectomy bilateral' 'Salpingo-oophorectomy' 'Salpingo-oophorectomy bilateral' 'Salpingo-oophorectomy unilateral')));
    ATTRIB os LABEL = "Oophorectomy**" FORMAT = ny.;
    os = 1;
RUN;
PROC SORT DATA=oophorectomy NODUPKEY; BY &subj_var.; RUN;

data adrp_trans;
    merge adsl_ext(in=sl) adrp_ext_trans(in=a) hysterectomy(in=b) oophorectomy(in=c);
    by &subj_var.;
    if sl;
    if b then hys=1;
    else hys =0;
    if c then os=1;
    else os =0;
    label hys = "Hysterectomy^&super_a";
    label os = "Oophorectomy^&super_b";
RUN;

ods escapechar="^";

%set_titles_footnotes(
    tit1 = "Table: Reproductive and menstrual history &fas_label"
  , ftn1 = "Placebo - Elinzanetant 120mg = Placebo for 12 weeks, followed by elinzanetant 120 mg for 14 weeks."
  , ftn2 = "a Based on Medical History. PTs considered for hysterectomy are: Hysterectomy, Hysterosalpingectomy, Hysterosalpingo-oophorectomy and Radical hysterectomy"
  , ftn3 = "b Based on Medical History. PTs considered for oophorectomy are: Hysterosalpingo-oophorectomy, Oophorectomy, Oophorectomy bilateral, Salpingo-oophorectomy, Salpingo-oophorectomy bilateral, Salpingo-oophorectomy unilateral"
  , ftn4 = 'SD = Standard Deviation.'
);

%desc_freq_tab(
    data     = adrp_trans
  , var      = pregnn pregnc brthn brthc amenlen hys os
  , var_freq = pregnc brthc hys os
  , data_n   = adsl_ext(WHERE=(&fas_cond.))
  , total    = yes
  , basepct  = N_CLASS
);



%endprog;