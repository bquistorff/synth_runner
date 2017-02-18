program _sr_gen_time_locals
	syntax , tper(int) prop(real) depvar(string) tvar_vals(numlist) outcome_pred_loc(string) ntraining_loc(string) ///
		nvalidation_loc(string)
	_sr_get_returns tvar=r(timevar) : tsset, noquery
	local tper_ind : list posof "`tper'" in tvar_vals
	local num_pre_per = `tper_ind'-1

	if `prop'==0 exit
	local ntraining = `num_pre_per'
	local nvalidation= 0
	if(`prop'<1){
		_assert `num_pre_per'>=2, msg("If training_propr<1 then need at least 2 periods pre-treatment for every treated unit")
		local ntraining = clip(1,int(`prop'*`num_pre_per'),`num_pre_per'-1)
		local nvalidation = `num_pre_per'-`ntraining'
	}
	forval i=1/`ntraining'{
		local period : word `i' of `tvar_vals'
		local olist = "`olist' `depvar'(`period')"
	}
	c_local `outcome_pred_loc' = "`olist'"
	c_local `ntraining_loc' = `ntraining'
	c_local `nvalidation_loc' = `nvalidation'
end
