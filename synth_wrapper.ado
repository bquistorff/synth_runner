*! version 1.0 Brian Quistorff <bquistorff@gmail.com>
*! Cleanups output and makes easier returns for -synth-
program synth_wrapper, eclass
	version 12 //haven't tested on earlier versions
	syntax anything, TRPeriod(numlist min=1 max=1 int) TRUnit(numlist min=1 max=1 int) [Keep(string) TREnds *]
	gettoken depvar predictors : anything
	
	local depvar_lbl : variable label `depvar'
	
	*-synth- doesn't use tempname sometimes where it should, so it might overwrite someone's mats
	local synth_exp_mats "matout vmat xcomat xtrmat fmat emat"
	foreach mat_name of local synth_exp_mats{
		cap mat drop `mat_name'
		if _rc==0 local found "yes"
	}
	if "`found'"=="yes" di "-synth- will destroy matrices: `synth_exp_mats'"
	
	preserve
	
	*alternatively could have demeaned the pre-treatment period, but follow CGNP13
	if "`trends'"!=""{
		gettoken depvar cov_predictors : anything
		tsset, noquery
		local pvar="`r(panelvar)'"
		local tvar="`r(timevar)'"
		tempvar v1 v2
		local match_per = `trperiod'-1
		qui gen `v1' = `depvar' if `tvar'==`match_per'
		by `pvar': egen `v2' = max(`v1')
		summ `v2' if `pvar'==`trunit' & `tvar'==`match_per', meanonly
		local scale = r(mean)
		qui replace `depvar' = (`depvar'/`v2')
	}
	
	synth `anything', keep(`keep') trperiod(`trperiod') trunit(`trunit') `options'
	
	*RMSPE should've been returned as a scalar (logically, and makes usage easier)
	tempname rmspe_mat
	mat `rmspe_mat' = e(RMSPE)
	local pre_rmspe = `rmspe_mat'[1,1]
	ereturn scalar pre_rmspe = `pre_rmspe'
	
	*get the post_RMSPE
	qui tsset
	local tper_ind = `trperiod'-r(tmin)+1
	local nper = rowsof(e(Y_treated))
	calc_RMSPE , i_start(`tper_ind') i_end(`nper') local(post_rmspe)
	ereturn scalar post_rmspe = `post_rmspe'
	
	*these matrices also shouldn've been deleted.
	cap mat drop `synth_exp_mats'
	
	*should've kept track of the types for id & period
	if "`keep'"!=""{
		use `keep', clear
		if "`trends'"!=""{
			rename (_Y_treated _Y_synthetic) (_Y_treated_scaled _Y_synthetic_scaled)
			gen _Y_treated = _Y_treated_scaled*`scale'
			gen _Y_synthetic = _Y_synthetic_scaled*`scale'
			label variable _Y_treated_scaled "Scaled `depvar_lbl'"
		}
		label variable _Y_treated "`depvar_lbl'"
		qui compress
		qui save `keep', replace
	}
end

