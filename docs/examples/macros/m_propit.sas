%MACRO m_propit(var=,exlow=,addlow=,fflag=Y,uplist=)
       / DES = 'Change race and ethnicity in required format';
/*******************************************************************************
 * Bayer AG
 * Macro rely on: ###choose: TOSCA, initstudy, GMS, GDD, pure SAS###
 *******************************************************************************
 * Purpose          : race and ethnicity variable in proper case
 * Programming Spec :
 * Validation Level : 1 - Verification by Review
 * Parameters       :
 *                    param1 :var, exlow
 *                    param1 :addlow, fflag and uplist
 * SAS Version      : Linux 9.4
 *******************************************************************************
 * Preconditions    :
 *     Macrovar. needed:
 *     Datasets  needed:
 *     Ext.Prg/Mac used:
 * Postconditions   :
 *     Macrovar created:
 *     Output   created:
 *     Datasets created:
 * Comments         :
 *******************************************************************************
 * Author(s)        : enpjp (Prashant Patel) / date: 26SEP2023
 * Reference prog   :
 *******************************************************************************
 * Change History   :
 ******************************************************************************/

/*******************************************************************************
 * Examples         :
   %macro();
 ******************************************************************************/

length &var._prop $200.;
 *Creating the lowercase the exception list;
  %let LowList='';
  %let OrgLowList=%str(a|an|and|at|but|by|down|for|in|of|on|or|out|over|past|so|the|to|up|with|yet|reported);
  %put Orginal LowList= &OrgLowList;
  %if &ExLow ne %then %do;
     %let LowList = %sysfunc(prxchange(s/\|(&ExLow)\b|\b(&ExLow)\|//i,-1,&OrgLowList));
     %put Lowlist with exception: &LowList;
  %end;
  %else %do;
     %let LowList=&OrgLowList;
  %end;
  %if &AddLow ne %then %do;
     %let LowList=%str(&LowList|&AddLow.);
  %end;
  %put LowList with Additions= &LowList;
  *Procase variable with lowcase exceptions;
  &var._Prop = prxchange("s/\b(?!(?:&LowList)\b)([a-z])([a-z]+)\b/\U$1\L$2/i", -1, lowcase(&var.));
  %if &FFlag=Y %then %do;
  &var._Prop=tranwrd(&var._Prop,scan(&var._Prop,1,' '),propcase(scan(&var._Prop,1,' ')));
     %if &UpList ne %then %do;
  &var._Prop=prxchange("s/\b(&UpList.)\b/\U$1/i",-1,&var._Prop);
     %end;
%end;


   %else %if &UpList ne %then %do;
  &var._Prop=prxchange("s/\b(&UpList.)\b/\U$1/i",-1,&var._Prop);
   %end;


%MEND m_propit;