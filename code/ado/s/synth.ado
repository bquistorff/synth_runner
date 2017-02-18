*! version 0.0.7  Jens Hainmueller 01/26/2014

program synth , eclass
  version 9.2
  preserve

/* check if data is tsset with panel and time var */
  qui tsset
  local tvar `r(timevar)'
  local pvar "`r(panelvar)'"
    if "`tvar'" == "" {
    di as err "panel unit variable missing please use -tsset panelvar timevar"
    exit 198
    }

    if "`pvar'" == "" {
    di as err "panel time variable missing please use -tsset panelvar timevar"
    exit 198
    }


 /* obtain settings */
  syntax anything , ///
                                     TRUnit(numlist min=1 max=1 int sort) ///
                                     TRPeriod(numlist min=1 max=1 int sort) ///
                                      [ COUnit(numlist min=2 int sort)  ///
                                       xperiod(numlist min=1 >=0 int sort) ///
                                       mspeperiod(numlist  min=1 >=0 int sort) ///
                                       resultsperiod(numlist min=1 >=0 int sort) ///
                                       unitnames(varlist max=1 string) ///
                                       FIGure ///
                                       Keep(string) ///
                                       REPlace ///
                                       customV(numlist) ///
                                       margin(real 0.005) ///
                                       maxiter(integer 1000) ///
                                       sigf(integer 12) ///
                                       bound(integer 10) ///
                                       nested ///
                                       allopt ///
                                       * ///
                                       ]


/* Define Tempvars and speperate Dvar and Predcitors */
   tempvar Xco Xcotemp Xtr Xtrtemp Zco Ztr Yco Ytr subsample misscheck conlabel

/* Check User Inputs  ************************* */

/* Treated an control unit numbers */

   /* Check if tr unit is found in panelvar */
    qui levelsof `pvar',local(levp)
    loc checkinput: list trunit in levp
    if `checkinput' == 0 {
     di as err "treated unit not found in panelvar - check tr()"
     exit 198
    }

   /* Get control units numbers */
   /* if user does not specify co() use all controls in pvar except treated */
   if "`counit'" == "" {
    local counit : subinstr local levp "`trunit'" " ", all word
   }
    else {
     /* else check if all user supplied co units are found in panelvar */
      loc checkinput: list counit in levp
      if `checkinput' == 0 {
       di as err "at least one control unit not found in panelvar - check co()"
       exit 198
      }
    /* and check if treat unit is among the controls */
     loc checkinput: list trunit in counit
     if `checkinput' == 1 {
      di as err "treated unit appears among control units  - check co() and tr()"
      exit 198
     }
   }

   /* if the panel vars has labels grab it */
   local clab: value label `pvar'
   /* if unitname specified, grab the label here */
   if "`unitnames'" != "" {
   /* check if var exists */
    capture confirm string var `unitnames'
            if _rc {
                di as err "`unitnames' does not exist as a (string) variable in dataset"
                exit 198
            }
    /* check if it has a value for all units */
    tempvar pcheck
    qui egen `pcheck' = sd(`pvar') , by(`unitnames')
    qui sum `pcheck'
    if r(sd) != 0 {
        di as err "`unitnames' varies within units of `pvar' - revise unitnames variable "
        exit 198
    }
    local clab "`pvar'"
    tempvar index
    gen `index' = _n
   /* now label the pvar accoringly */
    foreach i in `levp' {
        qui su `index' if `pvar' == `i', meanonly
        local label = `unitnames'[`r(max)']
        local value = `pvar'[`r(max)']
        qui label define `clab' `value' `"`label'"', modify
     }
   label value `pvar' `clab'
   }

   /* grab treated label for figure and control unit names */
   if "`clab'" != "" {
   local tlab: label `clab' `trunit' , strict
   foreach i in `counit' {
        local label : label `clab' `i'
        local colabels `"`colabels', `label'"'
     }
   local colabels : list clean colabels
   local colabels : subinstr local colabels "," ""
   local colabels : list clean colabels
   }

/* Produce initial output **************************** */
di as txt "{hline}"
di as res "Synthetic Control Method for Comparative Case Studies"
di as txt "{hline}"
di as txt ""
di as res "First Step: Data Setup"
di as txt "{hline}"

/* Build pre-treatment period */

  /*Check if intervention period is among timevar */
    qui levelsof `tvar', local(levt)
    loc checkinput: list trperiod in levt
    if `checkinput' == 0 {
    di as err "period of treatment is not not found in timevar - check trperiod()"
    exit 198
    }

  /* by default minmum of time var up to intervention (exclusive) is pre-treatment period */
    qui levelsof `tvar' if `tvar' < `trperiod' , local(preperiod)

  /* now if not supplied fill in xperiod (time period over which all predictors are averaged) */
   if "`xperiod'" == "" {
    numlist "`preperiod'" , min(1) integer sort
    local xperiod "`r(numlist)'"
   }
   else { /*else check whether user supplied xperiod is among timevar */
    loc checkinput: list xperiod in levt
    if `checkinput' == 0 {
     di as err "at least one time period specified in xperiod() not found in timevar"
     exit 198
    }
   }

  /* now if not supplied fill in mspeperiod (time period over which all loss is minimized are averaged) */
   if "`mspeperiod'" == "" {
    numlist "`preperiod'" , min(1) integer sort
    local mspeperiod "`r(numlist)'"
   }
   else { /* else check if user supplied mspeperiod is among timevar */
    loc checkinput: list mspeperiod in levt
    if `checkinput' == 0 {
     di as err "at least one time period specified in mspeperiod() not found in timevar"
     exit 198
    }
   }

 /* now if not supplied fill in resultsperiod (time period over which results are plotted) */
   if "`resultsperiod'" == "" {
    numlist "`levt'" , min(1) integer sort
    local resultsperiod "`r(numlist)'"
   }
   else { /* else check if user supplied mspeperiod is among timevar */
    loc checkinput: list resultsperiod in levt
    if `checkinput' == 0 {
     di as err "at least one time period specified in resultsperiod() not found in timevar"
     exit 198
    }
   }

/* now get dependent var */

/* get depvars */
gettoken dvar anything: anything
capture confirm numeric var `dvar'
            if _rc {
                di as err "`dvar' does not exist as a (numeric) variable in dataset"
                exit 198
            }

/* check if at leat one predictor is pecified */
 if "`anything'" == "" {
   di as err "not a single variable specified. please supply at least a response variable"
   exit 198
 }

/* *************************************************************************** */
/* Create X matrices */

  /* create void store matrix for treated and controls */
   local trno : list sizeof trunit
   local cono : list sizeof counit
  /* treated */
   qui mata: emptymat(`trno')
   mat `Xtr' = emat
  /* controls */
   qui mata: emptymat(`cono')
   mat `Xco' = emat

  /* for now we assume that the user used blanks only to seperate variables */
  /* thus we have p predictors */

  /* *************************** */
  /* begin variable construction   */
  while "`anything'" != "" {

   /* get token */
    gettoken p anything: anything , bind

    /* check if there is a paranthesis in token */
        local whereq = strpos("`p'", "(")
        if `whereq' == 0 {
      /* if not, token is just a varname and so check wheter this is a proper variable */
          capture confirm numeric var `p'
            if _rc {
                di as err "`p' does not exist as a (numeric) variable in dataset"
                exit 198
            }
          local var "`p'"
          local xtime "`xperiod'"
          /* set empty label for regular time period */
          local xtimelab ""

    } /* if yes, token is varname plus time, so try to disentagngle the two */
    else {
        /* get var */
            local var = substr("`p'",1,`whereq'-1)
            qui capture confirm numeric var `var'
            if _rc {
                di as err "`var' does not exist as a (numeric) variable in dataset"
                exit 198
            }
        /* get time token  */
            local xtime = substr("`p'",`whereq'+1,.)

        /* save time token to use for label */
            local xtimelab `xtime'
            local xtimelab : subinstr local xtimelab " " "", all

        /* now check wheter this is a second paranthsis */
            local wherep = strpos("`xtime'", "(")
         /* if no, delete a potential & and done */
            if `wherep' == 0 {
              local xtime : subinstr local xtime "&" " ", all
              local xtime : subinstr local xtime ")" " ", all
             } /* if yes, this is a numlist so we remove both paranthesis, but put the first one back in */
            else {
              local xtime : subinstr local xtime ")" " ", all
              local xtime : subinstr local xtime " " ")"
            }
              numlist "`xtime'" , min(1) integer sort
              local xtime "`r(numlist)'"

           /*Check if user supplied xtime period is among timevar */
             loc checkinput: list xtime in levt
             if `checkinput' == 0 {
              di as err "for predictor `var' some specified periods are not found in panel timevar"
              exit 198
             }


    } /* var and time construction done */

      /* now go an do averaging over xtime period for variable var   */

      /* Controls *************************** */
       /* Define Subsample (just control units and periods from xtime() ) */
        qui reducesample , tno("`xtime'") uno("`counit'") genname(`subsample')

       /* Deep Missing Checker (may be omitted to gain speed) */
        missingchecker , tno("`xtime'") cvar("`var'") sub("`subsample'") ulabel("control units") checkno(`cono') tilab("`xtimelab'")

       /* aggregate over years */
        agmat `Xcotemp' , cvar(`var') opstat("mean") sub(`subsample') ulabel("control units") checkno(`cono') tilab("`xtimelab'")


     /* Now treated ***************************** */
      /* Define subsample just treated unit and xtime() periods */
       qui reducesample , tno("`xtime'") uno("`trunit'") genname(`subsample')

      /* Deep Missing Checker (may be omitted to gain speed)  */
       missingchecker , tno("`xtime'") cvar("`var'") sub("`subsample'") ulabel("treated unit") checkno(`trno') tilab("`xtimelab'")

      /* and aggregate over years */
       agmat `Xtrtemp' , cvar(`var') opstat("mean") sub(`subsample') ulabel("treated unit") checkno(`trno') tilab("`xtimelab'")

      /* finally name matrices and done  */
       if "`xtimelab'" == "" {
        mat coln `Xcotemp' = "`var'"
        mat coln `Xtrtemp' = "`var'"
       }
        else {
        mat coln `Xcotemp' = "`var'(`xtimelab'"
        mat coln `Xtrtemp' = "`var'(`xtimelab'"
       }

     /* now take the final variable and cbind it to the store matrix  */
       mat `Xtr' = `Xtr',`Xtrtemp'
       mat `Xco' = `Xco',`Xcotemp'

  } /* close while loop through aynthing string, varibale construction is done */

   /* rownames for final X matrixes  */
   mat rown `Xco' = `counit'
   mat rown `Xtr' = `trunit'

   /* transpose for optimization */
   mat `Xtr' = (`Xtr')'
   mat `Xco' = (`Xco')'


/* Get Z matrix for controls ********************************* */
 agdvar `Zco' , cvar(`dvar') timeno(`mspeperiod') unitno(`counit') sub(`subsample') ///
                tlabel("pre-intervention MSPE period - check mspeperiod()") ///
                ulabel("control units") trorco("control")

/* Get Z matrix for treated ************************************************* */
 agdvar `Ztr' , cvar(`dvar') timeno(`mspeperiod') unitno(`trunit') sub(`subsample') ///
                tlabel("pre-intervention MSPE period - check mspeperiod()") ///
                ulabel("treated unit") trorco("treated")

/* Get Y matrix for controls ************************************************* */
 agdvar `Yco' , cvar(`dvar') timeno(`resultsperiod') unitno(`counit') sub(`subsample') ///
                  tlabel("results period - check resultsperiod()") ///
                  ulabel("control units") trorco("control")

/* Get Y matrix for treated ************************************************* */
 agdvar `Ytr' , cvar(`dvar') timeno(`resultsperiod') unitno(`trunit') sub(`subsample') ///
                  tlabel("results period - check resultsperiod()") ///
                  ulabel("treated unit") trorco("treated")

/* More Output *************************** */
di as txt "{hline}"
di as txt "Data Setup successful"
di as txt "{hline}"
if "`clab'" != "" {
di "{txt}{p 16 28 0} Treated Unit: {res}`tlab' {p_end}"
di "{txt}{p 15 30 0} Control Units: {res}`colabels' {p_end}"
}
 else {
di "{txt}{p 16 28 0} Treated Unit: {res}`trunit' {p_end}"
di "{txt}{p 15 30 0} Control Units: {res}`counit' {p_end}"
}
di as txt "{hline}"
di "{txt}{p 10 30 0} Dependent Variable: {res}`dvar' {p_end}"
di "{txt}{p 2 30 0} MSPE minimized for periods: {res}`mspeperiod'{p_end}"
di "{txt}{p 0 30 0} Results obtained for periods: {res}`resultsperiod'{p_end}"
di as txt "{hline}"
local prednames : rownames `Xco'
di "{txt}{p 18 30 0} Predictors:{res} `prednames'{p_end}"
di as txt "{hline}"
di "{txt}{p 0 30 0} Unless period is specified {p_end}"
di "{txt}{p 0 30 0} predictors are averaged over: {res}`xperiod'{p_end}"

/* now go to optimization */
/* ***************************************************************************** */
di as txt "{hline}"
di as txt ""
di as res "Second Step: Run Optimization"
di as txt "{hline}"

/* Dataprep finished. Starting optimisation */
tempname sval V

/* save vars for output */
mat `Xtrtemp' = `Xtr'
mat `Xcotemp' = `Xco'

/* normalize the vars */
mata: normalize("`Xtr'","`Xco'")
mat `Xtr' = xtrmat
mat `Xco' = xcomat

/* Set up V matrix */
if "`customV'" == "" {

/* If no custom V is provided go get Regression based V weights */
 mata: regsval("`Xtr'","`Xco'","`Ztr'","`Zco'")
 mat `V' = vmat

} /* Otherwise use the Custom V weights */
else {
      di as txt "Using user supplied custom V-weights"
      di as txt "{hline}"

      local checkinput : list sizeof customV
      if(`checkinput' != rowsof(`Xtr')) {
      di as err "wrong number of custom V weights; please specify one V-weight for each predictor"
      exit 198
     }
      else {
      mat input `sval' = (`customV')
      mata: normweights("`sval'")
      mat `V' = matout
     }
}


/* now go into optimization */

/* first set global optimization settings for quad prog. into matrices */
    global bd : tempvar
    global marg : tempvar
    global maxit : tempvar
    global sig : tempvar
    mat $bd = `bound'
    mat $marg = `margin'
    mat $maxit = `maxiter'
    mat $sig = `sigf'

/* set b slack parameter for quad prog. (always 1) */
    global bslack : tempvar
    mat $bslack = 1

/* now if the user wantes the full nested method, go and get Vstar via nested method  */
if "`nested'" == "nested" {

di "{txt}{p 0 30 0} Nested optimization requested {p_end}"

  /* parse the ml optimization options */
   /* retrieve optimization options for ml */
     mlopts std , `options'
   /* if no technique is specified insert our default */
     if "`s(technique)'" == "" {
       local technique "tech(nr dfp bfgs)"
       local std : list std | technique
     }

/*   /* if no iterations are specified insert our default */
      local std : subinstr local std "iterate" "iterate", count(local isinornot)
      if `isinornot' == 0 {
       local iterate " iterate(100)"
       local std : list std | iterate
      } */

   /* check wheter user has specified any of the nrtol options */
   /* 1. check if shownrtolernace is used */
      local std : subinstr local std "shownrtolerance" "shownrtolerance", count(local shownrtoluser)
       if `shownrtoluser' > 0 {
       di as err "maximize option shownrtolerance cannot be used with synth"
              exit 198
       }

   /* 2. check if own ntolernace level is specified  */
      local std : subinstr local std "nrtolerance(" "nrtolerance(", count(local nrtoluser)

   /* 3. check if nontolernace level is specified  */
      local std : subinstr local std "nonrtolerance" "nonrtolerance", count(local nonrtoluser)

   /* delete difficult if specified*/
     local std : subinstr local std "difficult" " ", all

 /* refine input matrices for ml optimization as globals so that lossfunction can find them */
  /* maybe there is a better way to do this */
   global Xco : tempvar
   global Xtr : tempvar
   global Zco : tempvar
   global Ztr : tempvar
   mat $Xco = `Xco'
   mat $Xtr = `Xtr'
   mat $Zco = `Zco'
   mat $Ztr = `Ztr'

 /* set up the liklihood model for optimization */
   /* since we optimize on matrices, we need to trick */
   /* ml and first simulate a dataset with correct dimensions */
    qui drop _all
    qui matrix pred = matuniform(rowsof(`V'),rowsof(`V'))
   /*  now create k articifical vars names pred1, pred2,... */
    qui svmat  pred

   /* get regression based V or user defined V as initial values */
    tempname bini
    mat `bini' = vecdiag(`V')

   /* Run optimization */
   tempname lossreg svalreg
   di "{txt}{p 0 30 0} Starting nested optimization module {p_end}"
   qui wrapml , lstd(`std') lbini("`bini'") lpred("pred*") lnrtoluser(`nrtoluser') lnonrtoluser(`nonrtoluser') lsearch("off")
   di "{txt}{p 0 30 0} Optimization done {p_end}"
   scalar define `lossreg' = e(lossend)
   mat `sval' = e(sval)

/* Now if allopt is specified then rerun optimization using ml search svals, and equal weights */
  if "`allopt'" == "allopt" {

   di "{txt}{p 0 30 0} Allopt requested. This may take a while{p_end}"

 /* **** */
 /* optimize with serach way of doing initial values  */
   tempname losssearch svalsearch
   di "{txt}{p 0 30 0} Restarting nested optimization module (search method) {p_end}"
   qui wrapml , lstd(`std') lbini("`bini'") lpred("pred*") lnrtoluser(`nrtoluser') lnonrtoluser(`nonrtoluser') lsearch("on")
   di "{txt}{p 0 30 0} done{p_end}"
   scalar define `losssearch' = e(lossend)
   mat `svalsearch' = e(sval)

 /* **** */
 /* optimize with equal weights way of doing initial values  */
     /* get equal weights */
        mat `bini' = vecdiag(I(rowsof(`V')))
     /* run opt */
      tempname lossequal svalequal
      di "{txt}{p 0 30 0} Restarting nested optimization module (equal method) {p_end}"
      qui wrapml , lstd(`std') lbini("`bini'") lpred("pred*") lnrtoluser(`nrtoluser') lnonrtoluser(`nonrtoluser') lsearch("off")
      di "done"
      scalar define `lossequal' = e(lossend)
      mat `svalequal' = e(sval)

 /* **** */
 /* Done with allopts optimization */

      /* now make a decision which loss is lowest. firt reg vs equal, then minimum vs search */
        if( `lossreg' < `lossequal' ) {
         mat `sval' = `svalequal'
         qui scalar define `lossreg' = `lossequal'
        }
        if( `lossreg' < `losssearch' ) {
         mat `sval' = `svalsearch'
        }

  } /* close allopt if */

   /* now get Vstar vector, normalize once again and create final diag Vstar */
    mata: getabs("`sval'")
    mat `sval' = matout
    mat `V' = diag(`sval')
}

/* now go get W, conditional on V (could be Vstar, regression V, or customV) */

tempname Xbal loss Ysynth Xsynth gap H c A b l u wsol

/* Set up quadratic programming */
 mat `H' =  (`Xco')' * `V' * `Xco'
 mat `c' = (-1 * ((`Xtr')' * `V' * `Xco'))'
 mat `A' = J(1,rowsof(`c'),1)
 mat `l' = J(rowsof(`c'),1,0)
 mat `u' = J(rowsof(`c'),1,1)

/* Initialize read out matrix  */
 matrix `wsol' = `l'

/* do quadratic programming step  */
 qui plugin call synthopt , `c' `H'  `A' $bslack `l' `u' $bd $marg $maxit $sig `wsol'

/* play back original X */
 mat `Xtr' = `Xtrtemp'
 mat `Xco' = `Xcotemp'

/* Compute loss and transform to RMSPE */
 mat `loss' = (`Ztr' - `Zco' * `wsol')' * ( `Ztr' - `Zco' * `wsol' )
 mat `loss' = `loss' / rowsof(`Ztr')
 mata: roottaker("`loss'")
 mat rowname `loss' = "RMSPE"


/* *************************************** */
/* Organize output */
 di as txt "{hline}"
 di as res "Optimization done"
 di as txt "{hline}"
 di as txt ""
 di as res "Third Step: Obtain Results"
 di as txt "{hline}"
 di as res "Loss: Root Mean Squared Prediction Error"
 matlist `loss' , tw(8) names(rows) underscore lines(rows) border(rows)
 di as txt "{hline}"
 di as res "Unit Weights:"

/* organize W matrix for display */
 tempvar counitno
 mat input `counitno' = (`counit')
 mat `counitno' = (`counitno')'

/* round */
 mata: roundmat("`wsol'")
 mat `wsol' = matout

/* cbind co and weights */
 tempvar wsolout
 mat `wsolout' =  `counitno' , `wsol'
 mat colname `wsolout' = "_Co_Number" "_W_Weight"
 qui svmat   `wsolout' , names(col)

/* Display either with or without colum names *********** */
 label var _Co_Number "Co_No"
 label values _Co_Number `clab'
 label var _W_Weight "Unit_Weight"
 tabdisp   _Co_Number if _Co_Number~=. ,c(_W_Weight)


/* Display X Balance */
  mat `Xsynth' = `Xco' * `wsol'
  mat `Xbal' = `Xtr' ,  `Xsynth'
  mat colname `Xbal' = "Treated" "Synthetic"

  di as txt "{hline}"
  di as res "Predictor Balance:"
  matlist `Xbal' , tw(30) border(rows)
  di as txt "{hline}"

 /*compute outcome trajectory output */
   mat `Ysynth' = `Yco' * `wsol'
   mat `gap'    = `Ytr' - `Ysynth'

/* if user wants plot or save */
if "`keep'" != "" | "`figure'" != "" {

 /* create vars for plotting */
   qui svmat double `Ytr' , names(_Ytreated)
   qui svmat double `Ysynth' , names(_Ysynthetic)
   qui svmat double `gap' , names(_gap)
 /* time variable for plotting */
   tempvar timetemp
   mat input `timetemp' = (`resultsperiod')
   mat `timetemp' = (`timetemp')'
   qui svmat double `timetemp' , names(_time)
 /* rename cosmetics */
   qui rename _Ytreated1   _Y_treated
   qui rename _Ysynthetic1 _Y_synthetic
   qui rename _gap1   _gap
   qui rename _time1  _time
   if "`clab'" != "" {
   qui label var  _Y_treated "`tlab'"
   qui label var  _Y_synthetic  "synthetic `tlab'"
   }
    else {
   qui label var  _Y_treated "treated unit"
   qui label var  _Y_synthetic  "synthetic control unit"
   qui label var _gap "gap in outcomes: treated minus synthetic"
   }
}

/* Results Dataset */
if "`keep'" != "" {
qui keep _Co_Number _W_Weight _Y_treated _Y_synthetic _time
qui drop if _Co_Number ==. & _Y_treated==.
 if "`replace'" != "" {
  qui save `keep' , `replace'
 }
  else {
  qui save `keep'
 }
}

/* Plot  */
if "`figure'" == "figure" {
twoway (line _Y_treated _time, lcolor(black)) (line _Y_synthetic _time, lpattern(dash) lcolor(black)), ytitle("`dvar'") xtitle("`tvar'") xline(`trperiod', lpattern(shortdash) lcolor(black))
}

/* Return results */
  qui ereturn clear
  ereturn mat Y_treated   `Ytr'
  ereturn mat Y_synthetic `Ysynth'
  if "`clab'" != "" {
  local colabels : subinstr local colabels " " "", all
  local colabels : subinstr local colabels "," " ", all
  local colabels : list clean colabels
  mat rowname `wsolout' = `colabels'
 }
  else {
  mat rowname `wsolout' = `counit'
}
  ereturn mat W_weights  `wsolout'
  ereturn mat X_balance   `Xbal'
  mat rowname `V' = `prednames'
  mat colname `V' = `prednames'
  ereturn mat V_matrix    `V'
  ereturn mat RMSPE `loss'

/* drop global macros */
macro drop Xtr Xco marg maxit sig bd bslack

*  ereturn mat X1    `Xtr'
*  ereturn mat X0    `Xco'
*  ereturn mat Z1    `Ztr'
*  ereturn mat Z0    `Zco'

/* main program ends here */

end


/* Subroutines */

/* subroutine reducesample: creates subsample marker for specified periods and units  */
program reducesample , rclass
  version 9.2
  syntax , tno(numlist >=0 integer) uno(numlist integer) genname(string)
  qui tsset
  local tvar `r(timevar)'
  local pvar `r(panelvar)'
  local tx: subinstr local tno " " ",", all
  local ux: subinstr local uno " " ",", all
  /* qui gen `genname' = ( inlist(`tvar',`tx') & inlist(`pvar', `ux')) */
  qui gen `genname' =  0 
  foreach cux of numlist `uno' {
   qui replace `genname'=1 if inlist(`tvar',`tx') & `pvar'==`cux'
  }
  end

/* subroutine missingchecker: goes through matrix, checks missing obs and gives informative error */
program missingchecker , rclass
  version 9.2
  syntax , tno(numlist >=0 integer) cvar(string) sub(string) ulabel(string)  checkno(string) [ tilab(string) ]
  qui tsset
  local tvar `r(timevar)'
   foreach tum of local tno {
    tempvar misscheck
    qui gen `misscheck' = missing(`cvar') if `tvar' == `tum' & `sub' == 1
    qui count if `misscheck' > 0 & `misscheck' !=.
     if `r(N)' > 0 {
      if "`tilab'" == "" {
       di as input "`ulabel': for `r(N)' of out `checkno' units missing obs for predictor `cvar' in period `tum' -ignored for averaging"
      }
       else {
       di as input "`ulabel': for `r(N)' of out `checkno' units missing obs for predictor `cvar'(`tilab' in period `tum' -ignored for averaging"
      }
     }
    qui drop `misscheck'
   }
end

/* subroutine gettabstatmat: heavily reduced version of SSC "tabstatmat" program by Nick Cox */
program gettabstatmat
        version 9.2
        syntax name(name=matout)
        local I = 1
        while "`r(name`I')'" != "" {
                local ++I
        }
        local --I
        tempname tempmat
        forval i = 1/`I' {
            matrix `tempmat' = nullmat(`tempmat') \ r(Stat`i')
            local names   `"`names' `"`r(name`i')'"'"'
        }
        matrix rownames `tempmat' = `names'
        matrix `matout' = `tempmat'
end

/* subroutine agmat: aggregate x-values over time, checks missing, and returns predictor matrix */
program agmat
       version 9.2
       syntax name(name=finalmat) , cvar(string) opstat(string) sub(string) ulabel(string) checkno(string) [ tilab(string) ]
       qui tsset
       local pvar `r(panelvar)'
       qui tabstat `cvar' if `sub' == 1 , by(`pvar') s(`opstat') nototal save
       qui gettabstatmat `finalmat'
       if matmissing(`finalmat') {
        qui local checkdimis : display `checkdimis'
        if "`tilab'" == "" {
         di as err "`ulabel': for at least one unit predictor `cvar' is missing for ALL periods specified"
         exit 198
        }
         else {
         di as err "`ulabel': for at least one unit predictor `cvar'(`tilab' is missing for ALL periods specified"
         exit 198
        }
       }
       qui drop `sub'
end

/* subroutine agdvarco: aggregates values of outcome varibale over time and returns in transposed form  */
/* has a trorco flag for treated or controls, since different aggregation is used */
program agdvar
       version 9.2
       syntax name(name=outmat) , cvar(string) timeno(numlist >=0 integer) ///
                                  unitno(numlist integer) sub(string) tlabel(string) ///
                                  ulabel(string) trorco(string)

       /* reduce sample */
       qui reducesample , tno("`timeno'") uno("`unitno'") genname(`sub')
       qui tsset
       local pvar `r(panelvar)'
       local tvar `r(timevar)'
       local tino : list sizeof timeno
       local cono : list sizeof unitno
        foreach tum of local timeno {
         qui sum `cvar' if `tvar' == `tum' & `sub' == 1 , meanonly
         tempname checkdimis checkdimshould
         qui scalar define `checkdimis' = `r(N)'
         qui scalar define `checkdimshould' = `cono'
         qui scalar define `checkdimis' = `checkdimshould' - `checkdimis'
         if `checkdimis' != 0 {
           qui local checkdimis : display `checkdimis'
           di as err "`ulabel': for `checkdimis' of out `cono' units outcome variable `cvar' is missing in `tum' `tlabel'"
           error 198
          }
         }

       /* aggregate for controls */
       if "`trorco'" == "control" {
        qui tsset
        local pvar `r(panelvar)'
        qui mata: switchmat("`pvar'","`cvar'", "`sub'")
        mat `outmat' = fmat
       }
        else {
      /* and for treated */
         qui mkmat `cvar' if `sub' == 1 , matrix(`outmat')
       }
      /* check missing */
       if matmissing("`outmat'") {
        di as err "`ulabel': outcome variable missing for `tlabel'"
        exit 198
       }
       mat coln `outmat' = `unitno'
       mat rown `outmat' = `timeno'
       qui drop `sub'
end

/* subroutine to run ml in robust way using difficult and without, plus with or without nrtol */
program wrapml , eclass
        version 9.2
syntax , lstd(string) lbini(string) lpred(string) lnrtoluser(numlist) lnonrtoluser(numlist) lsearch(string)

/* add search if specified */
if "`lsearch'" == "on" {
 local lsearch "search(quietly)"
 local lstd : list lstd | lsearch
}

di "started wrapml"
di "Std is: `lstd'"

 /* in any case we run twice once with and once without difficult specified */
 /* if user specifed any of the nrtol or nortol settings, give him exactly what he wants */
   tempname loss1 sval1 loss2 sval2
   if `lnrtoluser' > 0 | `lnonrtoluser' > 0 {
     di "user did specify nrtol setting"
     di "starting 1. attempt without difficult"
     qui ml model d0 synth_ll (xb: =  `lpred', noconstant), ///
      crittype(double) `lstd' maximize init(`lbini', copy) nowarning
      mat `sval1' = e(b)
      qui scalar define `loss1' = e(ll)
      di "done, loss is:"
      display `loss1'
      di "starting 2. attempt with difficult"

     /* now rerun with difficult */
      qui ml model d0 synth_ll (xb: =  `lpred', noconstant), ///
      crittype(double) `lstd' maximize init(`lbini', copy) nowarning difficult
      mat `sval2' = e(b)
      qui scalar define `loss2' = e(ll)
      di "done, loss is:"
      display `loss2'

   }
    else {
      /* if he did not, try first with nrtol then without */
      di "user did not specify nrtol settings"
      di "starting 1. attempt with nrtol and without difficult"
      qui capture ml model d0 synth_ll (xb: =  `lpred', noconstant), ///
      crittype(double) `lstd' maximize init(`lbini', copy) nowarning
      di "done"
       if _rc { /* if it breaks down we go with */
         di "optimization crashed. trying again with nonrtol and without difficult"
         qui ml model d0 synth_ll (xb: =  `lpred', noconstant), ///
         crittype(double) `lstd' maximize init(`lbini', copy) nowarning nonrtolerance
         mat `sval1' = e(b)
         qui scalar define `loss1' = e(ll)
         di "done, loss is:"
         display `loss1'
         }
          else { /* if it does not break down, store and go on */
        mat `sval1' = e(b)
        qui scalar define `loss1' = e(ll)
        di "optimization successful. loss is:"
        display `loss1'
        }

        /* now rerun with difficult */
        di "starting 2. attempt with nrtol and with difficult"
        qui capture ml model d0 synth_ll (xb: =  `lpred', noconstant), ///
        crittype(double) `lstd' maximize init(`lbini', copy) nowarning difficult
        if _rc { /* if it breaks down we go with */
         di "optimization crashed. trying again with nonrtol and with difficult"
         qui ml model d0 synth_ll (xb: =  `lpred', noconstant), ///
         crittype(double) `lstd' maximize init(`lbini', copy) nowarning nonrtolerance difficult
         mat `sval2' = e(b)
         qui scalar define `loss2' = e(ll)
        }
         else {
        mat `sval2' = e(b)
        qui scalar define `loss2' = e(ll)
        di "done, loss is:"
        display `loss2'
       }
   } /* close nrtol user specified or not */

di "end wrapml: results obtained"
di "loss1:"
display `loss1'
di "loss2:"
display `loss2'
di "and svals1 and 2"

  /* now make a decision which reg based loss is lowest */
        tempname sval lossend
        if `loss1' < `loss2' {
         mat `sval' = `sval2'
         qui scalar define `lossend' = `loss2'
        }
         else {
         mat `sval' = `sval1'
         qui scalar define `lossend' = `loss1'
        }

/* return loss and svals */
ereturn scalar lossend = `lossend'
ereturn matrix sval = `sval'

end


/* subroutine quadratic programming (C++ plugin) */
program synthopt, plugin
