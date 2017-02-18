program _sr_do_work_tr
	syntax anything, data(string) pvar(string) tper_var(string) tvar_vals(string) ///
		agg_file(string) ever_treated(string) [TREnds training_propr(real 0) pred_prog(string) ///
		drop_units_prog(string) *]
	gettoken depvar cov_predictors : anything

	local num_rep = _N
	tempname trs phandle
	mkmat `pvar' `tper_var' n, matrix(`trs')
	
	tempfile rmspes_f ind_file
	if `training_propr'>0 local pfile_open_var "val_rmspes"
	postfile `phandle' long(n) float(pre_rmspes post_rmspes `pfile_open_var') using "`rmspes_f'"
	qui use "`data'", clear
	forval g=1/`num_rep'{
		local tr_unit = `trs'[`g',1]
		local tper    = `trs'[`g',2]
		local n       = `trs'[`g',3]
		
		_sr_gen_time_locals , tper(`tper') prop(`training_propr') depvar(`depvar') tvar_vals(`tvar_vals') ///
			outcome_pred_loc(outcome_pred) ntraining_loc(ntraining) nvalidation_loc(nvalidation)
		if "`pred_prog'"!=""{
			`pred_prog' `tper'
			local add_predictors `"`r(predictors)'"'
		}
		preserve
		qui drop if `ever_treated' & `pvar'!=`tr_unit'
		if "`drop_units_prog'"!="" `drop_units_prog' `tr_unit'
		
		cap synth_wrapper `depvar' `outcome_pred' `cov_predictors' `add_predictors', `options' ///
			trunit(`tr_unit') trperiod(`tper') keep(`ind_file') replace `trends'
		if _rc==1 error 1
		if _rc{
			di as err "Error estimating treatment effect for unit `tr_unit'"
			error _rc
		}
		if `num_rep'>5  _sr_print_dots `g' `num_rep'
		if `training_propr'>0{
			calc_RMSPE , i_start(`=`ntraining'+1') i_end(`=`ntraining'+`nvalidation'') ///
				local(val_rmspe)
			local pfile_post "(`val_rmspe')"
		}
		post `phandle' (`n') (`e(pre_rmspe)') (`e(post_rmspe)') `pfile_post'

		_sr_add_keepfile_to_agg, keep(`ind_file') aggfile(`agg_file') tper_var(`tper_var') ///
			tper(`tper') unit(`tr_unit') depvar(`depvar') pre_rmspe(`e(pre_rmspe)') ///
			post_rmspe(`e(post_rmspe)')
		restore
	}
	postclose `phandle'
	use "`rmspes_f'", clear	
end
