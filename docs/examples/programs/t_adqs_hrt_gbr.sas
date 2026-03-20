/*******************************************************************************
 * Bayer AG
 * Study            : 21652 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adqs_hrt_gbr);
/*
 * Purpose          : History of menopause hormone therapy including participants from German sites only (FAS)
 * Programming Spec : see #runall
 * Validation Level : 2 - Verification by Double Programming
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : eaikp (Ajay  Sharma) / date: 05DEC2024
 * Reference prog   : /var/swan/root/bhc/3427080/21651/stat/query15/dev/pgms/t_adqs_hrt_gbr.sas (eaikp (Ajay  Sharma) / date: 05DEC2024)
 ******************************************************************************/

%load_ads_dat(adsl_view,
              adsDomain = adsl,
              where = (&fas_cond.),
              adslVars = );

%load_ads_dat(adqs_view,
              adsDomain = adqs,
              where = (parcat1 eq "HISTORY OF MENOPAUSE HORMONE THERAPY BAYER  V1.0"),
              adslVars = );


DATA adqs;
    MERGE adsl_view(IN=inadsl DROP=adsname) adqs_view(IN=inqs);
    BY studyid usubjid;
    IF inadsl AND inqs;
    FORMAT paramcd;
RUN;

data adqs_1;
    set adqs;
    if (paramcd in ("HMB102" "HMB105" "HMB107"
              "HMB108" "HMB109" "HMB110" "HMB111"  "HMB113" "HMB114"
              "HMB115" "HMB116" "HMB117" "HMB118" "HMB120" "HMB121"
    "HMB124" "HMB125" "HMB126" "HMB127" "HMB128" "HMB129" "HMB132" "HMB133" "HMB123" "HMB101")
    );
RUN;
data adqs1;
    length avalc_ $ 10;
        set adqs;
        if (paramcd in ("HMB102" "HMB105" "HMB107"
                                  "HMB108" "HMB109" "HMB110" "HMB111"  "HMB113" "HMB114"
                                  "HMB115" "HMB116" "HMB117" "HMB118" "HMB120" "HMB121"
                       "HMB124" "HMB125" "HMB126" "HMB127" "HMB128" "HMB129"
                       ) and avalc in ("CHECKED" ))
            or (paramcd in ("HMB132" "HMB133")
              and avalc in ("No")) then do;avalc_="No";flag="N";end;
            if flag ne "";
            keep usubjid flag avalc_;
RUN;

data adqs22;
        set adqs;
        if paramcd in ("HMB123" "HMB101");
RUN;

proc sort data=adqs22;
    by usubjid trt01pn trt01an;
RUN;
proc transpose data=adqs22 out=adqs2_;
    by usubjid trt01pn trt01an;
    var avalc;
    id paramcd;
RUN;
data adqs2__;
    length avalc_ $ 10;
    set adqs2_;
    if hmb101 eq "Participant never received any hormonal treatment for menopausal vasomotor symptoms" and
       hmb123 eq "Jointly by participant and physician based on individual benefit/risk assessment after physician's counseling" then do;avalc_="No";flag="N";end;
       if flag ne "";
       keep usubjid flag avalc_;
RUN;
data ff;
    set adqs1 adqs2__;
RUN;
proc sort data=ff out=adqs2 nodupkey;
    by usubjid;
RUN;
proc sort data=adqs_1;
    by usubjid;
RUN;
proc sort data=adqs;
    by usubjid;
RUN;
data fin;
    merge adqs_1(in=a) adqs2(in=b keep=usubjid flag avalc_);
    by usubjid;
    if a;
    if flag eq "" then do;
        flag="Y";avalc_="Yes";
    END;
RUN;
proc sort data=fin out=adqs23 nodupkey;
    by usubjid avalc_;
RUN;

data final;
    merge adqs(in=a) adqs23(in=b keep=usubjid flag avalc_);
    by usubjid;
    if a;
RUN;
proc sort data=final out=final_ nodupkey;
    by usubjid avalc_;
RUN;

ods escapechar="^";
%set_titles_footnotes(tit1 = "Table: Participants eligibility for HRT based on the primary and secondary conditions - GBA &fas_label."
                      );
%desc_freq_tab(
    data     = final_
  , var      = avalc_
  , class    = &treat_var_plan.
  , data_n   = adsl_view
  , subject  = usubjid
  , outdat   = _tab
  , misstext = Missing
  , stat     = n mean std min median max
  , optimal  = yes
  , maxlen   = 20
  , bylen    = 40
)

DATA _tab;
  LENGTH _varl_ $400;
  SET _tab;
  if _varl_ eq "AVALC_" then _varl_ = "Is participants eligible for HRT?";
  else if strip(_varl_) eq "n" then _varl_ ="  "||strip(_varl_);
  else _varl_ ="   "||strip(_varl_);
RUN;

%mosto_param_from_dat(
    data = _tabinp
  , var = g_call
)

%datalist(&g_call.);

%endprog();