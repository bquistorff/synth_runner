program _sr_do_work_do
	syntax anything, data(string) pvar(string) tper_var(string) tvar_vals(string) ///
		tper(string) agg_file(string) fail_file(string) [outcome_pred(string) ntraining(string) ///
		nvalidation(string) TREnds training_propr(real 0) drop_units_prog(string) ///
		aggfile_v(string) aggfile_w(string) max_pre(int -1) *]
	gettoken depvar cov_predictors : anything
	
	local num_reps = _N
	tempname dos phandle phandle_fail failed_opt_targets
	mkmat `pvar' n, matrix(`dos')
	
	tempfile rmspes_f ind_file
	mat `failed_opt_targets' = J(1,2,.)
	if `training_propr'>0 local pfile_open_var "val_rmspes"
	postfile `phandle' long(n) float(pre_rmspes post_rmspes `pfile_open_var') using "`rmspes_f'"
	postfile `phandle_fail' tper unit using "`fail_file'"
	
	qui use "`data'", clear
	
	//could have done this in the loop body in synth_runner, but I never load-up the data in there
	//prior to this so might be faster to have this here.
	if `max_pre'!=-1{
		_sr_get_returns tvar=r(timevar) : tsset, noquery
		local tper_ind : list posof "`tper'" in tvar_vals
		local earliest_good_ind = `tper_ind'-`max_pre'
		local earliest_good_val : word `earliest_good_ind' of `tvar_vals'
		qui drop if `tvar'<`earliest_good_val'
	}
	
	forval g=1/`num_reps'{
		local unit = `dos'[`g',1]
		local n    = `dos'[`g',2]
		
		preserve
		if "`drop_units_prog'"!="" qui `drop_units_prog' `unit'
		
		cap synth_wrapper `depvar' `outcome_pred' `cov_predictors', `options' ///
			trunit(`unit') trperiod(`tper') keep(`ind_file') replace `trends'
		if _rc==1 error 1
		if _rc==0{
			_sr_print_dots `g' `num_reps'
			local pre_rmspe = e(pre_rmspe)
			if `training_propr'>0{
				calc_rmspe , i_start(`=`ntraining'+1') i_end(`=`ntraining'+`nvalidation'') ///
					local(val_rmspe)
				local pfile_post "(`val_rmspe')"
			}
			post `phandle' (`n') (`e(pre_rmspe)') (`e(post_rmspe)') `pfile_post'
	
			_sr_add_keepfile_to_agg, keep(`ind_file') aggfile(`agg_file') tper_var(`tper_var') ///
				tper(`tper') unit(`unit') depvar(`depvar') pre_rmspe(`e(pre_rmspe)') ///
				post_rmspe(`e(post_rmspe)')
			
			if "`aggfile_v'"!="" & "`aggfile_w'"!="" {
				_sr_get_w_v, keep(`ind_file') ///
					tper(`tper') unit(`unit') aggfile_v(`aggfile_v') aggfile_w(`aggfile_w')
			}
			
		}
		else {
			_sr_print_dots `g' `num_reps' x
			post `phandle_fail' (`tper') (`unit') 
		}
		restore
	}
	postclose `phandle'
	postclose `phandle_fail' //this file will exist but might have 0 obs
	use "`rmspes_f'", clear	
end
