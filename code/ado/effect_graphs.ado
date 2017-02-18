*! version 1.0 Brian Quistorff <bquistorff@gmail.com>
*! Produces an 'effect' and 'treatment vs control' graphs
program effect_graphs
	version 12 //haven't tested on earlier versions
	syntax [, multi depvar_lbl(string) trunit(string) trperiod(string) depvar(string) trlinediff(real -1) ///
		depvar_synth(string) effect_var(string) effect_gname(string) tc_gname(string)]
	preserve
	
	if "`effect_gname'"=="" local effect_gname effect
	if "`tc_gname'"=="" local tc_gname tc
	tsset, noquery
	local pvar = "`r(panelvar)'"
	local tvar = "`r(timevar)'"
	
	if "`depvar_lbl'"=="" local depvar_lbl : variable label `depvar'
	
	if "`multi'"!=""{
		drop _all
		tempname treat_control b
		mat `treat_control' = e(treat_control)
		qui svmat `treat_control', names(o)
		tempvar depvar depvar_synth effect_var
		rename (o1 o2) (`depvar' `depvar_synth')
		gen `effect_var' = `depvar'-`depvar_synth'
		mat `b' = e(b)
		local npost = colsof(`b')
		gen long lead = _n-(_N-`npost')
		local tvar = "lead"
		local trperiod 1
	}
	else {
		if "`effect_var'"=="" local effect_var effect
		qui keep if `pvar'==`trunit'
	}

	twoway (line `effect_var' `tvar'), xline(`=`trperiod'-1') name(`effect_gname', replace) ///
		ytitle("Effect - `depvar_lbl'")

	twoway (line `depvar' `tvar') (line `depvar_synth' `tvar'), ///
		xline(`=`trperiod'+`trlinediff'') name(`tc_gname', replace) ytitle("`depvar_lbl'") ///
			legend(order(1 "Treated" 2 "Synthetic Control"))
end
