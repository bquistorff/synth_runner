*Compiles up the keep() files from synth
program _sr_add_keepfile_to_agg
	syntax , keep(string) aggfile(string) depvar(string) tper_var(string) tper(int) ///
		unit(int) pre_rmspe(real) post_rmspe(real)
	_sr_get_returns pvar=r(panelvar) tvar=r(timevar) : tsset, noquery
	preserve
	
	qui use "`keep'", clear
	drop _Co_Number _W_Weight
	qui drop if mi(_time) //other stuff in the file that might make it longer
	rename _time `tvar'
	rename _Y_treated* `depvar'*
	rename _Y_synthetic* `depvar'*_synth
	drop `depvar' //they have it wherever we merge into
	
	//note the "event" details
	gen long `pvar' = `unit'
	gen long `tper_var'=`tper'
	gen pre_rmspe = `pre_rmspe'
	gen post_rmspe = `post_rmspe'

	cap append using "`aggfile'"
	qui save "`aggfile'", replace
end
