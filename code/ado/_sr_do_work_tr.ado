program _sr_do_work_tr
	syntax anything, data(string) pvar(string) tper_var(string) tvar_vals(string) ///
		agg_file(string) ever_treated(string) [TREnds training_propr(real 0) pred_prog(string) ///
		drop_units_prog(string) max_pre(int -1) xperiod_prog(string) mspeperiod_prog(string) ///
		aggfile_v(string) aggfile_w(string) noredo_tr_error *]
	gettoken depvar cov_predictors : anything

	local num_rep = _N
	tempname trs phandle
	mkmat `pvar' `tper_var' n, matrix(`trs') //
	
	tempfile rmspes_f ind_file
	if `training_propr'>0 local pfile_open_var "val_rmspes"
	postfile `phandle' long(n) float(pre_rmspes post_rmspes `pfile_open_var') using "`rmspes_f'"
	qui use "`data'", clear
	_sr_get_returns tvar=r(timevar) pvar=r(panelvar) : tsset, noquery
	forval g=1/`num_rep'{
		local tr_unit = `trs'[`g',1]
		local tper    = `trs'[`g',2]
		local n       = `trs'[`g',3]
		
		preserve
		
		if `max_pre'!=-1{
			local tper_ind : list posof "`tper'" in tvar_vals
			local earliest_good_ind = `tper_ind'-`max_pre'
			local earliest_good_val : word `earliest_good_ind' of `tvar_vals'
			qui drop if `tvar'<`earliest_good_val'
		}
		
		_sr_gen_time_locals , tper(`tper') prop(`training_propr') depvar(`depvar') tvar_vals(`tvar_vals') ///
			outcome_pred_loc(outcome_pred) ntraining_loc(ntraining) nvalidation_loc(nvalidation) max_pre(`max_pre')
		macro drop _add_predictors _xperiod_opt _mspeperiod_opt
		if "`pred_prog'"!=""{
			`pred_prog' `tper'
			local add_predictors `"`r(predictors)'"'
		}
		if "`xperiod_prog'"!=""{
			`xperiod_prog' `tper'
			local xperiod_opt `"xperiod(`r(xperiod)')"'
		}
		if "`mspeperiod_prog'"!=""{
			`mspeperiod_prog' `tper'
			local mspeperiod_opt `"mspeperiod(`r(mspeperiod)')"'
		}
		
		qui drop if `ever_treated' & `pvar'!=`tr_unit'
		if "`drop_units_prog'"!="" qui `drop_units_prog' `tr_unit'
		loc synth_wrapper_cmd synth_wrapper `depvar' `outcome_pred' `cov_predictors' `add_predictors', `options' trunit(`tr_unit') trperiod(`tper') keep(`ind_file') replace `trends' `xperiod_opt' `mspeperiod_opt'
		cap `synth_wrapper_cmd'
		if _rc==1 error 1
		if _rc{
			di as err "Error estimating treatment effect for unit `tr_unit'"
			if "`redo_tr_error'"=="noredo_tr_error"{
				di as err "Try running -synth- directly on this unit"
				error _rc
			}
			else{
				* Sync list with synth_wrapper
				local synth_exp_mats "matout vmat xcomat xtrmat fmat emat"
				foreach mat_name of local synth_exp_mats{
					cap mat drop `mat_name'
				}
				di as err "Re-running last -synth- command with output/errors un-captured"
				`synth_wrapper_cmd'
			}
		}
		if `num_rep'>5  _sr_print_dots `g' `num_rep'
		if `training_propr'>0{
			calc_rmspe , i_start(`=`ntraining'+1') i_end(`=`ntraining'+`nvalidation'') ///
				local(val_rmspe)
			local pfile_post "(`val_rmspe')"
		}
		post `phandle' (`n') (`e(pre_rmspe)') (`e(post_rmspe)') `pfile_post'

		_sr_add_keepfile_to_agg, keep(`ind_file') aggfile(`agg_file') tper_var(`tper_var') ///
			tper(`tper') unit(`tr_unit') depvar(`depvar') pre_rmspe(`e(pre_rmspe)') ///
			post_rmspe(`e(post_rmspe)')
					
		if "`aggfile_v'"!="" & "`aggfile_w'"!="" {
			_sr_get_w_v, keep(`ind_file') ///
				tper(`tper') unit(`tr_unit') aggfile_v(`aggfile_v') aggfile_w(`aggfile_w')
		}
		restore
	}
	postclose `phandle'
	use "`rmspes_f'", clear	
end
