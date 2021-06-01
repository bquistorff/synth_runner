*Compiles up the keep() files from synth
program _sr_get_w_v
	syntax , keep(string) tper(int) ///
		unit(int) aggfile_w(string) aggfile_v(string)
	_sr_get_returns pvar=r(panelvar) tvar=r(timevar) : tsset, noquery
	preserve
	
	//Get's W the same way we get the Y_sc
	qui use "`keep'", clear
	
	drop _Y_treated _Y_synthetic _time
	qui drop if mi(_Co_Number) //other stuff in the file that might make it longer
	
	//note the "event" details
	gen long tr_`pvar' = `unit'
	gen long tr_`tvar'=`tper'
	
	cap append using "`aggfile_w'"
	qui save "`aggfile_w'", replace
	
	
	//Get V 
	tempname mymat
	mat `mymat' = vecdiag(e(V_matrix))
	clear
	qui svmat `mymat', names(V)
	gen long tr_`pvar' = `unit'
	gen long tr_`tvar' = `tper'
	
	cap append using "`aggfile_v'"
	qui save "`aggfile_v'", replace
end
