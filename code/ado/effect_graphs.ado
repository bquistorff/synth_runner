*! version 1.0 Brian Quistorff
*! Produces an 'effect' and 'treatment vs control' graphs
program effect_graphs
	version 12 //haven't tested on earlier versions
	syntax [, scaled trlinediff(real -1) tc_gname(string) effect_gname(string) ///
		treated_name(string) sc_name(string) tc_ytitle(string) effect_ytitle(string) ///
		tc_options(string) effect_options(string)]
	preserve
	
	_assert "`e(cmd)'"=="synth_runner", msg("Need to run this after -synth_runner- (with no other estimation routines in between).")
	local depvar       = cond("`scaled'"=="", "`e(depvar)'", "`e(depvar)'_scaled")
	local depvar_synth = "`depvar'_synth"
	local effect_var   = cond("`scaled'"=="", "effect", "effect_scaled")
	if "`effect_gname'"=="" local effect_gname effect
	if "`tc_gname'"=="" local tc_gname tc
	if "`treated_name'"=="" local treated_name "Treated"
	if "`sc_name'"=="" local sc_name "Synthetic Control"
	tsset, noquery
	local pvar = "`r(panelvar)'"
	local tvar = "`r(timevar)'"
	
	if "`tc_ytitle'"=="" & "`depvar'"!="" local tc_ytitle "`: variable label `depvar''"
	if "`effect_ytitle'"=="" & "`tc_ytitle'"!="" local effect_ytitle "Effect - `tc_ytitle'"
	
	if "`e(treat_type)'"!="single unit" local multi multi
	local trunit = "`e(trunit)'"
	local trperiod = "`e(trperiod)'"
	
	if "`multi'"!=""{
		drop _all
		tempname treat_control b
		mat `treat_control' = e(treat_control)
		qui svmat `treat_control', names(o)
		//note that I'm reusing the depvar local here
		tempvar depvar depvar_synth effect_var 
		rename (o1 o2) (`depvar' `depvar_synth')
		gen `effect_var' = `depvar'-`depvar_synth'
		mat `b' = e(b)
		local npost = colsof(`b')
		gen long lead = _n-(_N-`npost')
		label variable lead "Lead"
		local tvar = "lead"
		local trperiod 1
	}
	else {
		if "`effect_var'"=="" local effect_var effect
		cap confirm variable `effect_var'
		_assert _rc==0, msg(`"Effect variable [`effect_var'] does not exist, did you use the -, gen_vars- option in -synth_runner-?"') rc(111)
	
		qui keep if `pvar'==`trunit'
	}

	twoway (line `effect_var' `tvar'), xline(`=`trperiod'+`trlinediff'') name(`effect_gname', replace) ///
		ytitle("`effect_ytitle'") `effect_options'

	twoway (line `depvar' `tvar') (line `depvar_synth' `tvar'), ///
		xline(`=`trperiod'+`trlinediff'') name(`tc_gname', replace) ytitle("`tc_ytitle'") ///
			legend(order(1 "`treated_name'" 2 "`sc_name'")) `tc_options'
end
