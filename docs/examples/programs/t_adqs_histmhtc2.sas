

/*******************************************************************************
 * Bayer AG
 * Study            : 21652 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adqs_histmhtc2);
/*
 * Purpose          : History of menopause hormone therapy including participants from German sites only (FAS)
 * Programming Spec : see #runall
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : eaikp (Ajay Sharma) / date: 16AUG2024
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/query10/prod/pgms/t_adqs_histmht.sas (eitql (Anke Grohl) / date: 12JUL2024)
 ******************************************************************************/
/* Changed by       : eaikp (Ajay  Sharma) / date: 05SEP2024
 * Reason           : #drafting table for condition2#
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
    IF paramcd IN("HMB132" "HMB102" "HMB101" "HMB133" "HMB123" "HMB107" "HMB106" "HMB108" "HMB109" "HMB110" "HMB111" "HMB112" "HMB113" "HMB114");
    FORMAT paramcd;
RUN;

data adqs1;
        set adqs;
        where ((paramcd eq "HMB102" and avalc eq "CHECKED") or (paramcd eq "HMB106" and avalc eq "CHECKED") or
                                                              (paramcd eq "HMB107" and avalc eq "CHECKED")) or
              (paramcd IN("HMB108" "HMB109" "HMB110" "HMB111" "HMB112" "HMB113" "HMB114") and avalc eq "CHECKED")
              or (paramcd eq "HMB133" and avalc eq "No");
RUN;

data hmb101;
    set adqs;
    where  (paramcd eq "HMB101" and avalc eq "Participant never received any hormonal treatment for menopausal vasomotor symptoms") or
          (paramcd eq "HMB123" and avalc eq "Jointly by participant and physician based on individual benefit/risk assessment after physician's counseling");
    run;

PROC TRANSPOSE DATA=hmb101 OUT=hmb101_ ;
        VAR avalc;
        BY usubjid &treat_var_plan.;
        ID paramcd;
RUN;
data hmb101_2;
    length avalc $200;
        set hmb101_(where =(HMB101 ne "" and hmb123 ne "")) adqs1;
        avalc="Checked";
RUN;
PROC TRANSPOSE DATA=adqs OUT=mht ;
    VAR avalc;
    BY usubjid &treat_var_plan.;
    ID paramcd;
RUN;

data mht_;
        set mht;
        where HMB132 in ("Unknown" "Yes");
        flag="Y";
        keep usubjid flag;
RUN;
proc sort data=hmb101_2 nodupkey;
    by usubjid;
RUN;
data fin;
    merge hmb101_2(in=a) mht_(in=b);
    by usubjid;
    if a and b;
RUN;
DATA mht;
    SET mht END=eof;
    if HMB132 in ("Unknown" "Yes") then HMB132="Yes/Unknown";
    OUTPUT;
    IF eof THEN DO;
        HMB123='Other';
        CALL missing(usubjid, &treat_var_plan., hmb132, HMB102);
        OUTPUT;
    END;
RUN;
ods escapechar="^";
%set_titles_footnotes(tit1 = "Table: History of menopause hormone therapy-condition-2 &fas_label.",
                    ftn1 ="^&super_a participant meet the following conditions:",
                    ftn2 ='1) Never received HT due to existence of contra-indications according to label or not being aware of this treatment option or "other" reason OR',
                    ftn3 ="2) The participant received hormonal treatment for menopausal vasomotor symptoms (hot flashes) in the past and discontinues prior to becoming aware of the study or to participate to the study OR",
                    ftn4="3) Based on physical examination, medical history and counseling exchange, by investigator, in the role of a treating physician, assess the subject as Not appropriate/eligible for menopause hormone therapy OR",
                    ftn5="4) Never recieved HT and Jointly with the inverstigator took the decision not to take HT." );
%desc_freq_tab(
    data     = mht
  , var      = hmb132
  , class    = &treat_var_plan.
  , data_n   = adsl_view
  , subject  = usubjid
  , outdat   = _tab
  , misstext = Missing
  , stat     = n mean std min median max
  , optimal  = yes
  , maxlen   = 28
  , bylen    = 40
)
%desc_freq_tab(
    data     = fin(where=(paramcd ne 'HMB132'))
  , var      = avalc
  , class    = &treat_var_plan.
  , data_n   = mht(where=(hmb132 eq "Yes/Unknown"))
  , subject  = usubjid
  , outdat   = _tab1
  , missing  = NO
  , basepct  = n_class
  , misstext = Missing
  , stat     = n mean std min median max
  , optimal  = yes
  , maxlen   = 28
  , bylen    = 40
)


PROC SORT DATA=_tab;
    BY _widown _newvar _ord_;
RUN;
PROC SORT DATA=_tab1;
    BY _widown _newvar _ord_;
RUN;
/* Add long text for questions and change sort order of answers */
DATA _tab;
    retain x1 x2 x3;
    LENGTH _varl_ $400;
    SET _tab _tab1;
    if _varl_ eq "HMB132" then _varl_ = "Based on individual benefit/risk assessment for menopause hormone therapy, would the participant after medical counseling currently consider treatment with hormone therapy for menopausal vasomotor symptoms (hot flashes)?";;
    if _var_ eq "AVALC" then _varl_= "      Meeting the specified conditions^&super_a";
    if _var_ eq "AVALC" and _cptog1 eq "" then delete;
    array abc(3) _cptog1 _cptog2 _cptog3;
    array new(3) x1 x2 x3;
        do i=1 to 3;
            if index(abc(i)," (100%)")>0 then abc(i)=tranwrd(abc(i)," (100%)",")");
            abc(i)=tranwrd(abc(i)," N"," (N");
            if strip(_varl_) eq "n" then new(i)=input(strip(tranwrd(scan(abc(i),2,"="),")","")),best.);
            if input(strip(tranwrd(scan(abc(i),2,"="),")","")),best.) ne new(i) then
            abc(i)=tranwrd(abc(i),strip(tranwrd(scan(abc(i),2,"="),")","")),strip(put(new(i),best.)));
        END;
        if _var_ eq "AVALC" then do;_widown=3;_nr_=4;_type_=0;_ord_=1;_newvar=1;_widownr=4;_nr2_=3;end;
    IF _newvar NE 1 AND _ord_ > 1 THEN DO;
        IF _var_ EQ 'HMB101'
            THEN _ord_=ifn(strip(_varl_) EQ: 'Participant never',2,ifn(strip(_varl_) EQ: 'Participant received',3,4));
        IF _var_ IN ('HMB133' 'HMB132' 'HMB130')
            THEN _ord_=ifn(strip(_varl_) EQ 'No',2,ifn(strip(_varl_) EQ 'Yes',3,4));
        IF _var_ EQ 'AVALC'
            THEN do; _ord_=ifn(strip(_varl_) EQ: '      Meeting the',2,ifn(strip(_varl_) EQ: 'Jointly by',3,4));_widown=3;_nr_=4;_type_=0;_ord_=1;_newvar=1;_widownr=4;end;
    END;
    drop x1 x2 x3;
RUN;


%mosto_param_from_dat(
    data = _tabinp
  , var = g_call
)


%datalist(&g_call.);

%endprog();