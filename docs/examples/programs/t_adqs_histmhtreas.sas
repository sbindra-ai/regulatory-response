/*******************************************************************************
 * Bayer AG
 * Study            : 21652 A double-blind, randomized, placebo-controlled
 *   multicenter study to investigate efficacy and safety of elinzanetant for
 *   the treatment of vasomotor symptoms over 26 weeks in postmenopausal women
 * Proj/Subst/GIAD  : 3427080 / BAY 3427080, ELINZANETANT BAY3427080 NK1-3 RA Vasomotor Symptoms
 *******************************************************************************
 *Name of program**************************************************************/
   %iniprog(name = t_adqs_histmhtreas);
/*
 * Purpose          : History of menopause hormone therapy including participants from German sites only - reasons (FAS)
 * Programming Spec : see #runall
 * Validation Level : 1 - Verification by Review
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Pre-conditions   :
 * Post-conditions  :
 * Comments         :
 *******************************************************************************
 * Author(s)        : ealll (Jagadeesh Yakkala) / date: 13AUG2024
 * Reference prog   : /var/swan/root/bhc/3427080/21652/stat/query10/prod/pgms/t_adqs_histmhtreas.sas (eitql (Anke Grohl) / date: 12JUL2024)
 ******************************************************************************/
/* Changed by       : eaikp (Ajay  Sharma) / date: 22AUG2024
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
    MERGE adsl_view(IN=inadsl DROP=adsname)
          adqs_view(IN=inqs WHERE=(AVALC eq 'CHECKED' AND paramcd IN("HMB102" "HMB103" "HMB104" "HMB105" "HMB106" "HMB107"
                                                                     "HMB108" "HMB109" "HMB110" "HMB111" "HMB112" "HMB113" "HMB114"
                                                                     "HMB115" "HMB116" "HMB117" "HMB118" "HMB119" "HMB120" "HMB121")));
    BY studyid usubjid;
    IF inadsl AND inqs;
    aval=input(substr(paramcd,5,2),best.);
RUN;

%MACRO repbyif;

    %LOCAL i;
    %DO i=1 %TO 3;

        DATA adqs&i.;
            SET ADQS;
            FORMAT aval if&i.fmt.;
            %IF &i. EQ 1 %THEN %DO;
                IF paramcd IN("HMB102" "HMB103" "HMB104" "HMB105" "HMB106" "HMB107") THEN DO;
            %END;
            %ELSE %IF &i. EQ 2 %THEN %DO;
                IF paramcd IN("HMB108" "HMB109" "HMB110" "HMB111" "HMB112" "HMB113" "HMB114" ) THEN DO;
            %END;
            %ELSE %IF &i. EQ 3 %THEN %DO;
                IF paramcd IN("HMB115" "HMB116" "HMB117" "HMB118" "HMB119" "HMB120" "HMB121") THEN DO;
            %END;
                   item="IF&i.";
                    OUTPUT;
                END;
        RUN;

        %desc_freq_tab(
            data     = adqs&i.
          , var      = aval
          , class    = &treat_var_plan.
          , data_n   = adsl_view
          , subject  = usubjid
          , outdat   = _tab&i.
          , complete = ALL
          , misstext = Missing
          , stat     = n mean std min median max
          , optimal  = yes
          , maxlen   = 28
          , bylen    = 40
        );
    %END;
%MEND;

%repbyif;

DATA _tab1;
    SET _tab1(IN=in1) _tab2(IN=in2) _tab3(IN=in3);
    IF in1 THEN DO;
        _widownr=1;
        IF _varl_ EQ 'Analysis Value' THEN _varl_="If participant never received any hormonal treatment for menopausal vasomotor symptoms. Please provide the reason(s).";
    END;
    IF in2 THEN DO;
        _widownr=2;_nr_=2;_nr2_=3;_widown=2;
        IF _varl_ EQ 'Analysis Value' THEN _varl_="If participant received hormonal treatment for menopausal vasomotor symptoms in the past but discontinued treatment prior to becoming aware of this study. Please provide the reason(s).";
    END;
    IF in3 THEN DO;
        _widownr=3;_nr_=3;_nr2_=4;_widown=3;
        IF _varl_ EQ 'Analysis Value' THEN _varl_="If participant currently receives hormonal treatment for menopausal vasomotor symptoms but considers discontinuing treatment to participate in this study. Please provide the reason(s).";
    END;
RUN;


%set_titles_footnotes(
    tit1 = "Table: History of menopause hormone therapy - reasons &fas_label."
  , ftn1 = 'Some participants may be counted more than once, i.e., there is more than one response possible per patient'
);

%mosto_param_from_dat(
    data = _tab1inp
  , var = g_call
)

%datalist(&g_call.);

%endprog();