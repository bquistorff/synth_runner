program _sr_do_work_do
	syntax anything, data(string) pvar(string) tper_var(string) tvar_vals(string) ///
		tper(string) agg_file(string) fail_file(string) [outcome_pred(string) ntraining(string) ///
		nvalidation(string) TREnds training_propr(real 0) drop_units_prog(string) *]
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
	
	forval g=1/`num_reps'{
		local unit = `dos'[`g',1]
		local n    = `dos'[`g',2]
		
		preserve
		if "`drop_units_prog'"!="" `drop_units_prog' `unit'
		
		cap synth_wrapper `depvar' `outcome_pred' `cov_predictors', `options' ///
			trunit(`unit') trperiod(`tper') keep(`ind_file') replace `trends'
		if _rc==1 error 1
		if _rc==0{
			_sr_print_dots `g' `num_reps'
			local pre_rmspe = e(pre_rmspe)
			if `training_propr'>0{
				calc_RMSPE , i_start(`=`ntraining'+1') i_end(`=`ntraining'+`nvalidation'') ///
					local(val_rmspe)
				local pfile_post "(`val_rmspe')"
			}
			post `phandle' (`n') (`e(pre_rmspe)') (`e(post_rmspe)') `pfile_post'
	
			_sr_add_keepfile_to_agg, keep(`ind_file') aggfile(`agg_file') tper_var(`tper_var') ///
				tper(`tper') unit(`unit') depvar(`depvar') pre_rmspe(`e(pre_rmspe)') ///
				post_rmspe(`e(post_rmspe)')
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
