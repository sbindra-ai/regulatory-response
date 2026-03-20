/*******************************************************************************
 * Bayer AG
 * Study            : 21652 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adqs_histmht);
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
 * Author(s)        : ealll (Jagadeesh Yakkala) / date: 13AUG2024
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/query10/prod/pgms/t_adqs_histmht.sas (eitql (Anke Grohl) / date: 12JUL2024)
 ******************************************************************************/
/* Changed by       : eaikp (Ajay  Sharma) / date: 20AUG2024
 * Reason           : ###Removing country condition###
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
    IF paramcd IN("HMB101" "HMB133" "HMB132" "HMB123" "HMB130");
    FORMAT paramcd;
RUN;

PROC TRANSPOSE DATA=adqs OUT=mht ;
    VAR avalc;
    BY usubjid &treat_var_plan.;
    ID paramcd;
RUN;

DATA mht;
    SET mht END=eof;
    OUTPUT;
    IF eof THEN DO;
        HMB123='Other';
        CALL missing(usubjid, &treat_var_plan., hmb101, hmb133, hmb132, hmb130);
        OUTPUT;
    END;
RUN;

%set_titles_footnotes(tit1 = "Table: History of menopause hormone therapy &fas_label.");
%desc_freq_tab(
    data     = mht
  , var      = hmb101 hmb133 hmb132 hmb123 hmb130
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

PROC SORT DATA=_tab;
    BY _widown _newvar _ord_;
RUN;

/* Add "Other" as answer for HMB123 */
DATA _tab;
    SET _tab;
    BY _widown _newvar _ord_;
    OUTPUT;
    IF _var_ EQ 'HMB123' THEN DO;
        IF LAST._widown AND _ord_ NE 4 THEN DO;
            _ord_=4;
            _varl_='   Other';
            _cptog1=put(0,2.)||' ('||scan(_cptog1,-1,'(');
            _cptog2=put(0,2.)||' ('||scan(_cptog2,-1,'(');
            _cptog3=put(0,2.)||' ('||scan(_cptog3,-1,'(');
            OUTPUT;
        END;
    END;
RUN;

/* Add long text for questions and change sort order of answers */
DATA _tab;
    LENGTH _varl_ $400;
    SET _tab;
    SELECT (lowcase(_varl_));
        WHEN ('hmb101') _varl_ = "Has the participant ever received any hormonal treatment for menopausal vasomotor symptoms (hot flashes) in the past?";
        WHEN ('hmb133') _varl_ = "Based on physical examination, medical history and counseling exchange, would you as investigator, in the role of a treating physician, assess the subject as appropriate/eligible for menopause hormone therapy?";
        WHEN ('hmb132') _varl_ = "Based on individual benefit/risk assessment for menopause hormone therapy, would the participant after medical counseling currently consider treatment with hormone therapy for menopausal vasomotor symptoms (hot flashes)?";
        WHEN ('hmb123') _varl_ = "Who took the decision(s) to use / not to use / discontinue hormonal treatment for menopausal vasomotor symptoms in the past?";
        WHEN ('hmb130') _varl_ = "Does the participant have any personal risk factors that limit suitability of menopause hormone therapy?";
        OTHERWISE;
    END;
    IF _newvar NE 1 AND _ord_ > 1 THEN DO;
        IF _var_ EQ 'HMB101'
            THEN _ord_=ifn(strip(_varl_) EQ: 'Participant never',2,ifn(strip(_varl_) EQ: 'Participant received',3,4));
        IF _var_ IN ('HMB133' 'HMB132' 'HMB130')
            THEN _ord_=ifn(strip(_varl_) EQ 'No',2,ifn(strip(_varl_) EQ 'Yes',3,4));
        IF _var_ EQ 'HMB123'
            THEN _ord_=ifn(strip(_varl_) EQ: 'The participant',2,ifn(strip(_varl_) EQ: 'Jointly by',3,4));
    END;
RUN;

%mosto_param_from_dat(
    data = _tabinp
  , var = g_call
)

%datalist(&g_call.);

%endprog();