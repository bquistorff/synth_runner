program _sr_gen_time_locals
	syntax , tper(int) prop(real) depvar(string) tvar_vals(numlist) outcome_pred_loc(string) ntraining_loc(string) ///
		nvalidation_loc(string) [tvar(string) max_pre(int -1)]
	if "`tvar'"==""{
		_sr_get_returns tvar=r(timevar) : tsset, noquery
	}
	local tper_ind : list posof "`tper'" in tvar_vals
	if `max_pre'==-1 local max_pre = `tper_ind'-1
	local earliest_good_ind = `tper_ind'-`max_pre'

	if `prop'==0 exit
	local ntraining = `max_pre'
	local nvalidation= 0
	if(`prop'<1){
		_assert `max_pre'>=2, msg("If training_propr<1 then need at least 2 periods pre-treatment for every treated unit")
		local ntraining = clip(1,int(`prop'*`max_pre'),`max_pre'-1)
		local nvalidation = `max_pre'-`ntraining'
	}
	forval i=1/`ntraining'{
		local period : word `=`i'+`earliest_good_ind'-1' of `tvar_vals'
		local olist = "`olist' `depvar'(`period')"
	}
	c_local `outcome_pred_loc' = "`olist'"
	c_local `ntraining_loc' = `ntraining'
	c_local `nvalidation_loc' = `nvalidation'
end
