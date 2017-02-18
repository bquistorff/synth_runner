{smcl}
{* 26jan2014}{...}
{cmd:help synth} 
{hline}

{title:Title}

{p2colset 5 20 22 2}{...}
{p2col :{hi:synth} {hline 2}}Synthetic control methods for comparative case studies  {p_end}
{p2colreset}{...}


{title:Syntax}

{p 6 8 2}
{opt synth} {help synth##predoptions:{it:depvar}}  {help synth##predoptions:{it:predictorvars}} , {opt tru:nit}({it:#}) {opt trp:eriod}({it:#}) [ {opt cou:nit}({it:{help numlist:numlist}})  {cmd: xperiod}({it:{help numlist:numlist}}) 
{cmd: mspeperiod}() {cmd: resultsperiod}() {cmd: nested} {cmd: allopt} {cmd: unitnames}({it:{varname}}) {opt fig:ure}  {opt k:eep}({it:file}) {cmd: customV}({it:{help numlist:numlist}}) {help synth##osettings:{it:optsettings}} ]

{p 4 4 2}
Dataset must be declared as a (balanced) panel dataset using {cmd: tsset} {it:panelvar} {it:timevar}; see {help tsset}.
Variables
specified in {it:depvar} and {it:predictorvars} must be numeric variables; abbreviations are not allowed.
 

{title:Description}

{p 4 4 2}
{cmd:synth} implements the synthetic control method for causal inference in comparative case studies. {cmd:synth}
estimates the effect of an intervention of interest by comparing the evolution of an aggregate
outcome {it:depvar} for a unit affected by the intervention 
to the
evolution of the same aggregate outcome for a synthetic control group. {cmd:synth}
constructs this synthetic control group by searching for a weighted combination
 of control units chosen to approximate the unit affected by the intervention 
in terms of the outcome predictors.
The evolution of the outcome for the resulting synthetic control group is an estimate of 
the counterfactual of what would have been observed for the
affected unit in the absence of the intervention. {cmd:synth} can also be used to 
conduct a variety of placebo and permutation tests that produce informative inference regardless of the number of available comparison units and the
number of available time-periods. See Abadie and Gardeazabal (2003) and Abadie, Diamond, and Hainmueller (2010, 2014) for details.

{title:Required Settings}

{p 4 8 2}
{marker predoptions}
{cmd: depvar} the outcome variable.

{p 4 8 2}
{cmd: predictorvars} the list of predictor variables. By default, 
all predictor variables are averaged over the entire pre-intervention period, which
ranges from the earliest time period available in the panel time variable specified in {cmd: tsset} {it:timevar} to
the period immediately prior to the intervention specified in {cmd: trperiod}. Missing values 
are ignored in the averages.{p_end} 
{p 8 8 2}
The user has two
options to flexibly specify the time periods over which predictors are averaged:{p_end}

{p 10 10 2}
(1) {cmd: xperiod}({it:numlist}) allows to specify a common
period over which all predictors should be averaged; see 
below for details.{p_end}

{p 10 10 2}
(2) For each particular predictor the user can specify the period over which the
variable will be averaged. For this, {cmd: synth} uses a specialized syntax.
The time period is specified in parenthesis directly following the variable name, e.g. varname({it:period}) with
no blanks between the variable name and its {it:period}. {it:period} can
contain either a single period, a {help numlist} of periods, or several periods concatenated by a "&". 
The periods refer to the panel time variable specified in {cmd: tsset} {it:timevar}. For example, assume 
the time periods are given in years, and there are four predictors X1, X2, X3, and X4 then:{p_end}

{p 10 10 2}
{cmd:. synth Y X1(1980) X2(1982&1986&1988) X3(1980(1)1990) X4}{p_end}

{p 10 10 2}
indicates that:{p_end}
{p 12 12 2}
{cmd:X1(1980)}: the value of the variable X1 in the year 1980 is entered as a predictor.{p_end}

{p 12 12 2}
{cmd:X2(1982&1986&1988)}: the value of the variable X2 averaged over the years 1982,
1986, and 1988 is entered as a predictor.{p_end}

{p 12 12 2}
{cmd:X3(1980(1)1990)}: the value of the variable X3 averaged over the years 1980,1981,...,1990
is entered as a predictor.{p_end}

{p 12 12 2}
{cmd:X4}: since no variable specific period is provided, the value of the
variable X4 is averaged either over the entire
pretreatment period (default) or the period specified in {cmd: xperiod}({it:numlist}) and then entered as a predictor.{p_end}

{p 4 8 2}
{cmd:trunit}({it:#}) the unit number of the unit affected by the intervention as given in the 
panel id variable specified in {cmd: tsset} {it:panelvar}; see {help tsset}. Notice that only a single unit number 
can be specified. If the intervention of interest affected several units the user may chose to combine these units first and
then treat them as a single unit affected by the intervention.

{p 4 8 2}
{cmd:trperiod}({it:#}) the time period when the intervention occurred. The time period
 refers to the panel time variable specified in {cmd: tsset} {it:timevar};
 see {help tsset}. Only a single number can be specified.

{title:Options}

{p 4 8 2}
{cmd: counit}({it:numlist}) a list of unit numbers for the control 
units as given in the panel id variable specified in {cmd: tsset} {it:panelvar}; see {help tsset}. {cmd: counit()}
should be specified as a list of integer numbers (see {help numlist}) and contain at least two control units.
The list of control units specified constitute what is called the `donor pool', the 
set of potential control units out of which the synthetic control unit is constructed. 
Notice that {cmd: counit} is optional, if no {cmd: counit} is specified, the donor pool defaults to all units available in
the panel id variable specified in {cmd: tsset}, excluding the unit affected by the intervention
specified in {cmd: trunit}.

{p 4 8 2}
{cmd: xperiod}({it:numlist}) a list of time periods over which the predictor variables
 specified in {help synth##predoptions:{it:predictorvars}}
are averaged. The list of time periods refers to the panel time variable specified in {cmd: tsset} {it:timevar}. 
For example, if the specified panel time variable is given in years, {cmd: xperiod}(1980(1)1988) 
indicates that the predictor variables are averaged over all years from 1980, 1981,...,1988. See {help numlist} on how to 
specify lists of numbers.{p_end} 
{p 8 8 2}
If no {cmd: xperiod} is specified, {cmd: xperiod} defaults to the entire pre-intervention period, which by default
ranges from the earliest time period available in the panel time variable to the 
period immediately prior to the intervention. Notice that the
period of the intervention itself is excluded from the average and missing entries are ignored. 
Also notice that variable-specific time periods always take precedence over {cmd: xperiod}.
Usually, {cmd: xperiod} is specified to contain a number of pre-intervention periods, although post-intervention 
time periods could be included if the predictors are not affected by the intervention.{p_end}

{p 4 8 2}
{cmd: mspeperiod}({it:numlist}) a list of pre-intervention time periods over which the mean squared prediction error (MSPE) 
should be minimized. The list of time periods refers to the panel time variable specified in {cmd: tsset} {it:timevar};
 see {help tsset}. The MSPE refers to the squared deviations between the outcome for the treated unit
 and the synthetic control unit summed over all pre-intervention periods specified in {it:mspeperiod(numlist)}. See {help numlist} on how to specify lists of numbers.
{p_end}
{p 8 8 2}
If no {cmd: mspeperiod()} is specified, {cmd: mspeperiod()} defaults to the entire
 pre-intervention period ranging from the earliest time period available in the panel time variable to
the period immediately prior to the intervention. Notice that the
period of the intervention itself is excluded from {cmd: mspeperiod()}.
Usually, the 
{cmd: mspeperiod()} is specified to cover the whole pre-treatment period up to the time of the intervention, 
but other choices are 
possible.{p_end}


{p 4 8 2}
{cmd: resultsperiod}({it:numlist}) a list of time periods over which the results of {cmd: synth} 
should be obtained in the optional figure (see {cmd: figure}), the optional results dataset (see {cmd:keep}),
and the return matrices (see {cmd: ereturn results})). The list of time periods refers to the panel time variable specified in {cmd: tsset} {it:timevar}. 
If no {cmd: resultsperiod} is specified, {cmd: resultsperiod} defaults to the entire period, which by default
ranges from the earliest to the latest time period available in the panel time variable.{p_end}

{p 4 8 2}
{cmd:nested} by default {cmd: synth} uses a data-driven regression based
method to obtain the variable weights contained in the V-matrix. This method 
relies on a constrained quadratic programming routine, that finds the best fitting W-weights 
conditional on the regression based V-matrix. This procedure is fast and
often yields satisfactory results in terms of minimizing the MSPE. 
Specifying {cmd:nested} will lead to better performance, however, at the expense of additional computing time. 
If {cmd:nested} is specified
{cmd:synth} embarks on an fully nested optimization procedure
 that searches among all (diagonal) positive semidefinite V-matrices
and sets of W-weights for the best fitting convex combination of the control units.
The fully nested optimization 
contains the regression based V as a starting point, but often produces convex combinations that
achieve even lower MSPE. If {cmd: customV} is specified and {cmd: nested} is specified,
the user supplied V-matrix form the starting point for the nested optimization. 
All parameters of both optimizers can be tuned by the user depending on
his application (see  {help synth##info:{it:optimset}}).

{p 4 8 2}
{cmd: allopt} if nested is specified (see {cmd:nested}) the user can also 
specify {cmd: allopt} if she is willing to trade-off even more computing time 
in order to gain fully robust results. Sometimes the search space may 
contain local minima such that the nested optimization procedure starting from the
regression based V-matrix may not find the global minimum in the parameter space.
{cmd: allopt} provides 
a robustness check by running the nested optimization three times using three 
different starting points (the regression based V, equal V-weights, and a third 
procedure that uses Stata's {help ml search} procedure to find good starting values.
{cmd: synth} returns the best result of all three attempts. This option
usually will take three times the amount of computing time compared to the {cmd: nested} option.
Often {cmd: allopt}
will lead to no improvement over just the {cmd: nested} method, but sometime {cmd: allopt} produces even better results.

{p 4 8 2}
{cmd: unitnames}({it:{varname}}) a string variable that contains unit names. The unit names refer
 to the unit numbers in the panel id variable specified in {cmd: tsset} {it:pvar};
 see {help tsset}. If {cmd: unitnames} is provided the results will be displayed with unit numbers labeled by their respective unit names. So for example, if the user has two variables in his dataset called country_numbers (numeric) and country_names (string), {cmd: unitnames(country_names)} could be specified to display the results using country names instead of numbers. Alternatively, if the user does not specify 
{cmd: unitnames}, but his panel id variable is labeled, the labels from the latter will be used.

{p 4 8 2}
{cmd: figure} if specified {cmd:synth} produces a line plot with outcome trends for the treated unit and the synthetic control unit 
for the years specified in {it:resultsperiod()}. 

{p 4 8 2}
{cmd:keep(}{it:filename}{cmd:)} saves a dataset with the 
results in the file {it: filename}{cmd:.dta}. This dataset can be used to further process the results.

{p 8 8 2}
If {cmd:keep(}{it:filename}{cmd:)} is specified, {it:filename}{cmd:.dta} will hold the following variables:

{p 8 17 15}
{cmd:_time:}{p_end}
{p 12 12 15}
A variable that contains the respective time period (from the {cmd: tsset} panel time variable ({it:timevar})) 
for all periods specified in {it:resultsperiod()}.{p_end}

{p 8 17 15}
{cmd:_Y_treated:}{p_end}
{p 12 12 15}
The observed outcome {it:depvar} for the treated unit 
specified in {it:tr()} for each time period specified in {it:resultsperiod()}.{p_end}

{p 8 17 15}
{cmd:_Y_synthetic:}{p_end}
{p 12 12 15}
The estimated outcome {it:depvar} for the synthetic control unit  
estimated using the convex combination of the control units specified in {it:co()} for each time period specified in
{it:resultsperiod()}.{p_end}

{p 8 17 15}
{cmd:_Co_Number:}{p_end}
{p 12 12 15}
A variable that contains the unit number (from the {cmd: tsset} panel unit variable ({it:panelvar}) for each control unit
specified in {it:co()}. If unit names are supplied via {it:conames()} the unit numbers will be labeled accordingly (each control unit 
number is labeled with its respective name from {it:conames()}. 

{p 8 17 15}
{cmd:_W_weight:}{p_end}
{p 12 12 15}
A variable that contains the estimated unit weight for each control units specified in 
{it:co()}. 

{p 4 8 2}
{cmd:replace} replaces the dataset specified in 
{cmd:keep(}{it:filename}{cmd:)} if it already exists.

{p 4 8 2}
{cmd:customV}({it:numlist}) by default {cmd: synth} uses a data-driven regression based
method to obtain the variable weights contained in the V-matrix. {cmd: customV}()
gives the user the option to supply custom V-Weights instead. 
Notice that the V-weights determine the 
predictive power of the respective variable for the outcome of interest over the
pre-intervention period. Highly predictive variables should be given a high weight, 
so that the unit affected by the intervention and the
synthetic control unit match strongly on this predictor.
Weights are specified as
a list with weights appearing in the same order as the predictors 
listed in  {help synth##predoptions:{it:predictorvars}}.
One weight must be supplied for each predictor. See the papers in the
references for details. For now, only one weight per variable is allowed (the V matrix is 
diagonal), but future releases will allow non-diagonal V matrices to be supplied.

{marker osettings}
{title:Optimization Settings:}
{synoptline}
Control parameters for the {it: constrained quadratic optimization routine}:

{p 5 5 2}
 The constrained quadratic optimization routine is based on an algorithm that uses the interior point method
 to solve the constrained quadratic programming problem (see Vanderbei 1999 for more details on the interior point method).
It is implemented via a C++ plugin and has the following 
tuning parameters:{p_end}

{p 8 8 2}
{opt "margin(real)"} Margin for constraint violation tolerance. Default is 5 percent (ie. 0.05).{p_end}
{p 8 8 2}
{opt "maxiter(#)"} Maximum number of iterations. Default is 1000.{p_end}
{p 8 8 2}
{opt "sigf(#)"} Precision (no of significant figures). Default is 7.{p_end}
{p 8 8 2}
{opt "bound(#)"} Clipping bound for the variables. Default is 10.{p_end}

{p 4 4 2}

Additional control parameters for the {it: nested optimization routine}:

{p 5 5 2}
If {cmd: nested} is specified, a nested optimization will be performed using the 
constrained quadratic programming routine and Stata's {help ml} optimizer. By default, {cmd: synth}
 uses the {help maximize} default settings. The user 
may tune the {help maximize} settings depending on his application (e.g. like
synth ... , iterate(20) ).{p_end}
{synoptline}

{title:Saved Results}

{p 4 8 2}
By default, {cmd:synth} ereturns the following matrices, which 
can be displayed by typing {cmd: ereturn list} after 
{cmd: synth} is finished (also see {help ereturn}).  

{p 8 8 2}
{cmd: e(V_matrix):}{p_end}
{p 10 10 2}
A diagonal matrix that contains the normalized variable weights in the diagonal.

{p 8 8 2}
{cmd: e(X_balance) :}{p_end}
{p 10 10 2}
A matrix that juxtaposes the predictor values for the unit affected by the intervention
and the synthetic control unit. The matrix has two columns (treated and synthetic) and as many rows as predictors. 

{p 8 8 2}
{cmd: e(W_weights) :}{p_end}
{p 10 10 2}
A matrix that contains the unit numbers and unit weights, ie. the relative contribution of each control unit to the synthetic control unit.
The matrix has two column and as many rows as control units.

{p 8 8 2}
{cmd: e(Y_treated) :}{p_end}
{p 10 10 2}
A matrix that contains the values of the response variable for the treated unit for each time period.
The matrix has one column and as many rows as time periods specified in {cmd:resultsperiod()}. 

{p 8 8 2}
{cmd: e(Y_synthetic) :}{p_end}
{p 10 10 2}
A matrix that contains the values of the response variable for the synthetic control unit 
for each time period.
The matrix has one column and as many rows as time periods specified in {cmd:resultsperiod(). 

{p 8 8 2}
{cmd: e(RMSPE) :}{p_end}
{p 10 10 2}
A one by one matrix that contains the Root Mean Squared Prediction Error (RMSPE)}. 


{title:Examples}

{p 4 8 2}
Load Example Data: This panel dataset contains information for 39 US States for the years 1970-2000
(see Abadie, Diamond, and Hainmueller (2010) for details).{p_end}
{p 4 8 2}{stata "sysuse smoking":. sysuse smoking}{p_end}

{p 4 8 2}
Declare the dataset as panel:{p_end}
{p 4 8 2}{stata "tsset state year":. tsset state year}{p_end}

{p 4 8 2}
Example 1 - Construct synthetic control group:{p_end}
{phang}{stata synth cigsale beer(1984(1)1988) lnincome retprice age15to24 cigsale(1988) cigsale(1980) cigsale(1975), trunit(3) trperiod(1989)}

{p 8 8 2}
In this example, the unit affected by the intervention is unit no 3 (California) in the year 1989.
The donor pool (since no {cmd: counit()} is specified) defaults to the control units 1,2,4,5,...,39 (
ie. the other 38 states in the dataset). 
Since no {cmd: xperiod()} is provided, the predictor variables for which
no variable specific time period is specified
(retprice, lnincome, and age15to24) are averaged over the 
entire pre-intervention period up to the year of the intervention (1970,1981,...,1988).
The beer variable has the time period (1984(1)1988) specified, meaning that it is
averaged for the periods 1984,1985,...,1988. The variable cigsale 
will be used three times as a predictor using the values from periods 1988, 1980, and 1975 respectively. 
The MSPE is minimized over the entire pretreatment period, because {cmd: mspeperiod()} is not
provided. By default, results are displayed for the 
period from 1970,1971,...,2000 period (the earliest and latest year in the dataset).{p_end}

{p 4 8 2}
Example 2 - Construct synthetic control group:{p_end}
{phang}{stata synth cigsale beer  lnincome(1980&1985)  retprice  cigsale(1988) cigsale(1980) cigsale(1975), trunit(3) trperiod(1989) fig}

{p 8 8 2}
This example is similar to example 1, but now beer is averaged over the
entire pretreatment period while lnincome is only averaged over the periods 1980 and 1985.
Since no data is available for beer prior to 1984, {cmd: synth} will inform the user 
that there is missing data for this variable and that the missing values 
are ignored in the averaging. A results figure is also requested using the {cmd: fig} option. {p_end}

{p 4 8 2}
Example 3 - Construct synthetic control group:{p_end}
{phang}{stata synth cigsale retprice cigsale(1970) cigsale(1979) , trunit(33) counit(1(1)20) trperiod(1980) fig resultsperiod(1970(1)1990)}

{p 8 8 2}
In this example, the unit affected by the intervention is state no 33, and the donor pool of
potential control units is restricted to states no 1,2,...,20. 
The intervention occurs in 1980, and results are obtained for the 1970,1971,...,1990 period.{p_end}

{p 4 8 2}
Example 4 - Construct synthetic control group:{p_end}
{phang}{stata synth cigsale retprice cigsale(1970) cigsale(1979) , trunit(33) counit(1(1)20) trperiod(1980) resultsperiod(1970(1)1990) keep(resout)}

{p 8 8 2}
This example is similar to example 2 but {cmd: keep(resout)} is specified and thus {cmd: synth} will save a dataset named resout.dta
in the current Stata working directory (type {cmd: pwd} to see the path of your working directory). This dataset contains the 
result from the current fit and can be used for further processing. Also to easily access results recall that {cmd: synth} routinely returns all result matrices. These can be displayed by typing {cmd: ereturn list} after 
{cmd:synth} has terminated.{p_end}

{p 4 8 2}
Example 5 - Construct synthetic control group:{p_end}
{phang}{stata synth cigsale beer lnincome retprice age15to24 cigsale(1988) cigsale(1980) cigsale(1975) , trunit(3) trperiod(1989) xperiod(1980(1)1988) nested}

{p 8 8 2}
This is again example 2, but the {cmd: nested} option is specified, which typically produces a better fit at the 
expense of additional computing time. Alternativley, the user can also specified the {cmd: allopt} option which 
can improve the fit even further and requires yet more computing time. Also, {cmd: xperiod()} is specified indicating that 
predictors are averaged for the 1980,1981,...,1988 period. {p_end}

{p 4 8 2}
Example 5 – Run placebo in space:{p_end}
{phang}{cmd:. tempname resmat} {break}
{cmd: forvalues i = 1/4   {c -(}}{break}
{cmd:      synth cigsale retprice cigsale(1988) cigsale(1980) cigsale(1975) , trunit(`i') trperiod(1989) xperiod(1980(1)1988) } {break}
{cmd:      matrix `resmat' = nullmat(`resmat') \ e(RMSPE)} {break}
{cmd:      local names   `"`names' `"`i'"'"'}{break}
{cmd:{c )-}} {break}
{cmd: mat colnames `resmat' = "RMSPE"}{break}
{cmd: mat rownames `resmat' = `names'}{break}
{cmd:matlist `resmat' , row("Treated Unit")}

{p 8 8 2}
This is a code example to run placebo studies by iteratively reassigning the intervention in space to the first four states. To do so, we simply run a four loop each where the {cmd:trunit()} setting is incremented in each iteration. Thus, in the first run of {cmd: synth} state number one is assigned to the intervention, in the second run state number two, etc, etc. In each run we store the RMSPE and display it in a matrix at the end.{p_end}



{title:References}

{p 4 8 2}
Abadie, A., Diamond, A., and J. Hainmueller. 2014. Comparative Politics and the Synthetic Control Method. American Journal of Political Science (Forthcoming 2014).

{p 4 8 2}
Abadie, A., Diamond, A., and J. Hainmueller. 2010. Synthetic Control Methods for Comparative Case Studies: Estimating the Effect of California's Tobacco Control Program.
{it: Journal of the American Statistical Association} 105(490): 493-505.

{p 4 8 2}
Abadie, A. and Gardeazabal, J. 2003. Economic Costs of Conflict:
     A Case Study of the Basque Country. American Economic Review 93(1): 113-132.

{p 4 8 2}
Vanderbei, R.J. 1999. LOQO: An interior point code for quadratic programming.
{it: Optimization Methods and Software} 11: 451-484. 

{title:Authors}

      Jens Hainmueller, jhain@stanford.edu
      Stanford

      Alberto Abadie, alberto_abadie@harvard.edu
      Harvard University

      Alexis Diamond, adiamond@fas.harvard.edu
      IFC
