*! version 1.6.0 Brian Quistorff
*! Automates the process of conducting many synthetic control estimations
program synth_runner, eclass
	version 12 //haven't tested on earlier versions
	if "`1'" == "version"{
		synth_runner_version
		exit
	}
	
	syntax anything, [ ///
		D(varname) ///
		ci ///
		pvals1s ///
		noredo_tr_error ///
		TREnds ///
		training_propr(real 0) ///
		max_lead(numlist min=1 max=1 int >=0)  ///
		noenforce_const_pre_length ///
		Keep(string) ///
		REPlace ///
		GEN_vars ///
		TRPeriod(numlist min=1 max=1 int) ///
		TRUnit(numlist min=1 max=1 int) ///
		pre_limit_mult(numlist max=1 >=1) ///
		n_pl_avgs(string) ///
		PARallel DETerministicoutput ///
		pred_prog(string) ///
		drop_units_prog(string) ///
		xperiod_prog(string) ///
		mspeperiod_prog(string) ///
		aggfile_v(string) aggfile_w(string) ///
		COUnit(string) FIGure resultsperiod(string)  ///
		xperiod(numlist min=1 >=0 int sort) mspeperiod(numlist  min=1 >=0 int sort) *]
		
	gettoken depvar cov_predictors : anything
	_sr_get_returns pvar=r(panelvar) tvar=r(timevar) bal=r(balanced): qui tsset
	* Stata's dta file operations (save/use/merge) will automatically add dta to extensionless files, so do that too.
	if `"`keep'"'!=""{
		_getfilename `"`keep'"'
		if `=strpos(`"`r(filename)'"',".")'==0{
			local keep `"`keep'.dta"'
		}
	}
	if "`gen_vars'"!=""{
		if `"`keep'"'=="" tempfile keep
		local new_vars "lead `depvar'_synth effect pre_rmspe post_rmspe"
		if "`trends'"!="" {
			local new_vars "`new_vars' `depvar'_scaled `depvar'_scaled_synth effect_scaled"
		}
		cap confirm new variable `new_vars'
		_assert _rc==0, msg("With -, gen_vars- the program needs to be able create the following variables: `new_vars'. Please make sure there are no such varaibles and that the dependent variable [`depvar'] has a short enough name that the generated vars are not too long (usually a max of 32 characters).")
	
	}
	
	_assert "`bal'"=="strongly balanced", msg("Panel must be strongly balanced. See -tsset-.")
	
	_assert "`d'`trperiod'`trunit'"!="", msg("Must specify treatment units and time periods (d() or trperiod() and trunit())")
	_assert "`d'"=="" | "`trperiod'`trunit'"=="" , msg("Can't specify both d() and {trperiod(), trunit()}")
	if "`d'"==""{
		tempvar D
		gen byte `D' = (`pvar'==`trunit' & `tvar'>=`trperiod')
	}
	else local D "`d'"
	
	//catch options not allowed to be sent to -synth-
	_assert "`counit'"=="", msg("counit() option not allowed. Non-treated units are assumed to be controls. Remove units that are neither controls nor treatments before invoking.")
	_assert "`figure'"=="", msg("figure option not allowed.")
	_assert "`resultsperiod'"=="", msg("resultsperiod() option not allowed. Use max_lead() or drop selected post-periods.")
	
	if "`pre_limit_mult'"=="" local pre_limit_mult .
	_assert ("`n_pl_avgs'"=="" | "`n_pl_avgs'"=="all" | real("`n_pl_avgs'")!=.), msg("-, n_pl_avgs()- must be blank, a number, or all")
	_assert ("`xperiod'"=="" | "`xperiod_prog'"==""), msg("Can not specify both xperiod() and xperiod_prog()")
	_assert ("`mspeperiod'"=="" | "`mspeperiod_prog'"==""), msg("Can not specify both mspeperiod() and mspeperiod_prog()")
	if "`xperiod'"!=""    local options "xperiod(`xperiod') `options'"
	if "`mspeperiod'"!="" local options "mspeperiod(`mspeperiod') `options'"
	
	//check for needed programs
	cap synth
	_assert _rc!=199, msg(`"-synth- must be installed (available from SSC, {stata "ssc install synth":ssc install synth})."')
	if "`parallel'"!=""{
		cap parallel
		_assert _rc!=199, msg(`"-parallel- must be installed if option used (available from SSC or http://github.com/gvegayon/parallel)."')
		
		_assert "$PLL_CLUSTERS"!="", msg("You must use -parallel setclusters XXX- before using the parallel option for -synth_runner-.")
	}
	if "`aggfile_v'`aggfile_w'"!="" {
		_assert "`aggfile_v'"!="", msg("Must specify both aggfile_v and aggfile_w or neither")
		_assert "`aggfile_w'"!="", msg("Must specify both aggfile_v and aggfile_w or neither")
		cap erase "`aggfile_v'"
		cap erase "`aggfile_w'"
	}
	
	tempvar ever_treated tper_var0 tper_var event
	tempname trs uniq_trs pvals pvals_t estimates CI pval_pre_RMSPE pval_val_RMSPE ///
		tr_pre_rmspes tr_val_rmspes do_pre_rmspes do_val_rmspes p1 p2 tr_post_rmspes ///
		do_post_rmspes pval_post_RMSPE pval_post_RMSPE_t disp_mat out_ef n_pl n_pl_used ///
		failed_opt_targets
	tempfile agg_file out_e fail_file no_tr_pids
		
	qui bys `pvar': egen `tper_var0' = min(`tvar') if `D'
	qui bys `pvar': egen `tper_var' = max(`tper_var0')
	*Get a list of repeated treatment dates
	preserve
	qui keep if !mi(`tper_var')
	collapse (first) `tper_var', by(`pvar')
	sort `tper_var' `pvar'
	mkmat `pvar' `tper_var', matrix(`trs')
	contract `tper_var'
	sort `tper_var'
	mkmat `tper_var' _freq, matrix(`uniq_trs')
	local num_tpers = rowsof(`uniq_trs')
	restore
	if `num_tpers'>1{
		_assert "`keep'"=="", msg("Can only keep if one period in which units receive treatment")
		if "`xperiod'"!="" di "With multliple time periods you may want to use xperiod_prog() instead of xperiod()"
		if "`mspeperiod'"!="" di "With multliple time periods you may want to use mspeperiod_prog() instead of mspeperiod()"
		local treat_type="multiple periods"
	}
	cleanup_mata , tr_table(`uniq_trs') pre_limit_mult(`pre_limit_mult') warn
	
	
	qui levelsof `tvar', local(tvar_vals)
	local n_tvar_vals : list sizeof tvar_vals
	
	//Lead numbering. A bit weird as lead0 is last pre-treatment
	qui summ `tper_var', meanonly
	//qui gen `lead' = `tvar' - `tper_var'+1 
	local min_trperiod = r(min)
	local max_trperiod = r(max)
	local min_trperiod_ind : list posof "`min_trperiod'" in tvar_vals
	local max_trperiod_ind : list posof "`max_trperiod'" in tvar_vals
	local min_lead = 1+(1-`min_trperiod_ind') //min lead (max "lag") with common support.
	local max_lead_avail = `n_tvar_vals' - `max_trperiod_ind' + 1

	if "`max_lead'"!=""{
		if `max_lead'>`max_lead_avail'{
			di "You specified a max_lead longer than is available in the data. Reducing to max possible."
			local max_lead =`max_lead_avail'
		}
	}
	else{
		local max_lead =`max_lead_avail'
	}
	
	//Get row labels for the treatment-relevant stats
	//the 'lead' variable is integer (including 0) and lead1=post1, so lead0=pre1, lead-1=pre2, etc.
	//This is unintuitive, so label them as "... pre2 pre1 post1 post2 ..."
	local max_post = `max_lead'
	forval post=1/`max_post'{
		local postlist "`postlist' post`post'"
	}
	local max_pre_const = -1*`min_lead' + 1
	forval pre=`max_pre_const'(-1)1{
		local prelist "`prelist' pre`pre'" 
	}
	local plist "`prelist' `postlist'"
	
	
	if "`enforce_const_pre_length'"=="noenforce_const_pre_length" local max_pre_opt "max_pre(`max_pre_const')"
	
	bys `pvar': egen byte `ever_treated'=max(`D')
	
	qui levelsof `pvar', local(units)
	qui levelsof `pvar' if `ever_treated'==1, local(tr_units)
	
	di as result "Estimating the treatment effects"
	local num_tr_units : list sizeof tr_units
	if "`treat_type'"!="multiple periods"{
		if `num_tr_units'==1 {
			local treat_type = "single unit"
			local tt_trunit = `tr_units'
		}
		else {
			local treat_type = "single period"
		}
		local tt_trperiod = `uniq_trs'[1,1]
	}
	tempfile maindata maindata_no_tr
	qui save "`maindata'"
	drop _all
	qui svmat `trs', names(col)
	gen long n = _n
	
	if ("`parallel'"!="" & `num_tr_units'>1){
		//figure out which programs need to passed to parallel
		foreach v in drop_units_prog pred_prog xperiod_prog mspeperiod_prog{
			cap findfile ``v''.ado
			if (_rc) local tr_programs_copy `tr_programs_copy' ``v''
		}
		local do_par "parallel, outputopts(agg_file) programs(`tr_programs_copy') `deterministicoutput':"
	}
	`do_par' _sr_do_work_tr `depvar' `cov_predictors', data("`maindata'") pvar(`pvar') ///
		tper_var(`tper_var') tvar_vals(`tvar_vals') ever_treated(`ever_treated') ///
		`trends' training_propr(`training_propr') agg_file(`agg_file') pred_prog(`pred_prog') ///
		drop_units_prog(`drop_units_prog') `max_pre_opt' xperiod_prog(`xperiod_prog') ///
		mspeperiod_prog(`mspeperiod_prog') aggfile_v(`aggfile_v') aggfile_w(`aggfile_w') ///
		`redo_tr_error' `options'
	sort n
	mkmat pre_rmspes, matrix(`tr_pre_rmspes')
	mkmat post_rmspes, matrix(`tr_post_rmspes')
	if `training_propr'>0 mkmat val_rmspes, matrix(`tr_val_rmspes')
	qui use "`maindata'", clear
	
	cleanup_and_convert_to_diffs, dta(`agg_file') out_effect(`out_e') min_lead(`min_lead') ///
		out_effect_full(`out_ef') max_lead(`max_lead') depvar(`depvar') `trends' tper_var(`tper_var')
	if "`keep'"!="" qui copy "`agg_file'" "`keep'", `replace'
	load_dta_to_mata, dta(`out_e') mata_var(tr_effects)
	mata: tr_effect_avg = mean(tr_effects)
	mata: st_matrix("`estimates'", tr_effect_avg)
	mat colnames `estimates' = `leadlist'
	mat rownames `estimates' = `D'
	mata: tr_pre_rmspes = st_matrix("`tr_pre_rmspes'")
	mata: tr_t_effect_avg = mean(tr_effects :/ (tr_pre_rmspes*J(1,`max_lead',1)))
	mata: tr_post_rmspes = st_matrix("`tr_post_rmspes'")
	mata: tr_post_rmspes_t_avg = mean(tr_post_rmspes :/ tr_pre_rmspes)
	
	
	di "Estimating the possible placebo effects (one set for each of the `num_tpers' treatment periods)"
	local do_units : list units - tr_units
	local num_do_units : list sizeof do_units
	foreach mat_v in do_effects_p do_t_effects_p do_pre_rmspes_p do_post_rmspes_p do_post_rmspes_t_p do_val_rmspes_p{
		mata: `mat_v' = J(`num_tr_units',1,NULL)
	}
	
	preserve
	qui drop if `ever_treated'
	qui save "`maindata_no_tr'", replace
	qui by `pvar': keep if _n==1
	keep `pvar'
	gen long n = _n
	qui save "`no_tr_pids'"
	
	local do_aggs_i 1
	*Be smart about not redoing matches at the same time.
	scalar `n_pl' = 1
	if ("`parallel'"!=""){
		cap findfile `drop_units_prog'.ado
		if (_rc) local do_programs_copy `do_programs_copy' `drop_units_prog'
		local do_par "parallel, outputopts(agg_file fail_file) programs(`do_programs_copy') `deterministicoutput':"
	}
	forval i=1/`num_tpers'{
		local tper = `uniq_trs'[`i',1]
		local times =`uniq_trs'[`i',2]

		_sr_gen_time_locals , tper(`tper') prop(`training_propr') depvar(`depvar') tvar_vals(`tvar_vals') ///
			outcome_pred_loc(outcome_pred) ntraining_loc(ntraining) nvalidation_loc(nvalidation) `max_pre_opt' tvar(`tvar')
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
			
		//pass in the unit ids to estimate
		qui use "`no_tr_pids'", clear
		
		cap erase "`agg_file'"
		tempfile fail_file_do_round
		`do_par' _sr_do_work_do `depvar' `cov_predictors' `add_predictors', data("`maindata_no_tr'") ///
			pvar(`pvar') tper_var(`tper_var') tvar_vals(`tvar_vals') outcome_pred(`outcome_pred') ///
			ntraining(`ntraining') nvalidation(`nvalidation') tper(`tper') `trends' ///
			training_propr(`training_propr') `options' agg_file("`agg_file'") fail_file("`fail_file_do_round'") ///
			drop_units_prog(`drop_units_prog') aggfile_v(`aggfile_v') aggfile_w(`aggfile_w') ///
			`xperiod_opt' `mspeperiod_opt' `max_pre_opt'
		qui append_to, appendage(`fail_file_do_round') body(`fail_file')
		sort n
		if _N!=`num_do_units' local failed_o = 1
		mkmat pre_rmspes, matrix(`do_pre_rmspes')
		mkmat post_rmspes, matrix(`do_post_rmspes')
		if `training_propr'>0 mkmat val_rmspes, matrix(`do_val_rmspes')
		
		qui use "`maindata_no_tr'", clear //for cleanup_and_convert_to_diffs
		cleanup_and_convert_to_diffs, dta(`agg_file') out_effect(`out_e') depvar(`depvar') ///
			tper_var(`tper_var') `trends' max_lead(`max_lead')
		load_dta_to_mata, dta(`out_e') mata_var(do_effect_base`i')
		mata: do_pre_rmspe_base`i' = st_matrix("`do_pre_rmspes'")
		mata: do_t_effect_base`i' = do_effect_base`i' :/ (do_pre_rmspe_base`i'*J(1,`max_lead',1))
		mata: do_post_rmspe_base`i' = st_matrix("`do_post_rmspes'")
		mata: do_post_rmspe_t_base`i' = do_post_rmspe_base`i' :/ do_pre_rmspe_base`i'
		if `training_propr'>0 mata: do_val_rmspe_base`i' = st_matrix("`do_val_rmspes'")
		forval j=1/`times'{
			local j_suff ""
			if `pre_limit_mult'!=.{
				local j_suff "_`j'"
				local pre_rmspe_max = `pre_limit_mult'*`tr_pre_rmspes'[`do_aggs_i',1]
				mata: good_enough_ind = (do_pre_rmspe_base`i':<=`pre_rmspe_max')
				mata: do_effect_base`i'`j_suff' = select(do_effect_base`i',good_enough_ind)
				mata: do_pre_rmspe_base`i'`j_suff' = select(do_pre_rmspe_base`i',good_enough_ind)
				mata: do_t_effect_base`i'`j_suff' = select(do_t_effect_base`i',good_enough_ind)
				mata: do_post_rmspe_base`i'`j_suff' = select(do_post_rmspe_base`i',good_enough_ind)
				mata: do_post_rmspe_t_base`i'`j_suff' = select(do_post_rmspe_t_base`i',good_enough_ind)
				if `training_propr'>0 mata: do_val_rmspe_base`i'`j_suff' = select(do_val_rmspe_base`i',good_enough_ind)
			}

			mata: st_numscalar("`n_pl'", st_numscalar("`n_pl'")*rows(do_effect_base`i'`j_suff'))
			mata: do_effects_p[`do_aggs_i',1]    = &do_effect_base`i'`j_suff'
			mata: do_pre_rmspes_p[`do_aggs_i',1] = &do_pre_rmspe_base`i'`j_suff'
			mata: do_t_effects_p[`do_aggs_i',1]  = &do_t_effect_base`i'`j_suff'
			mata: do_post_rmspes_p[`do_aggs_i',1]= &do_post_rmspe_base`i'`j_suff'
			mata: do_post_rmspes_t_p[`do_aggs_i',1]= &do_post_rmspe_t_base`i'`j_suff'
			if `training_propr'>0 mata: do_val_rmspes_p[`do_aggs_i',1] = &do_val_rmspe_base`i'`j_suff'
			local ++do_aggs_i
		}
	}
	cap load_dta_to_matrix, dta("`fail_file'") matrix(`failed_opt_targets')
	if "`keep'"!="" qui append_to, appendage(`agg_file') body(`keep')
	restore
	
	local num_steps = cond(`training_propr'>0,6,5)
	local default_max_n_pl 1000000
	if "`n_pl_avgs'"==""{
		if `default_max_n_pl'<`n_pl'{
			scalar `n_pl_used' = `default_max_n_pl'
			di _n "The number of placebo averages (`=`n_pl'') is more than the default max (`default_max_n_pl')" _continue
			di " so switching to a random sample of `default_max_n_pl'. To override use -, n_pl_avgs()-."
		}
		else {
			scalar `n_pl_used' = `n_pl'
		}
	}
	else {
		if "`n_pl_avgs'"=="all"    scalar `n_pl_used' =     `n_pl'
		else /* specified #*/ scalar `n_pl_used' = min(`n_pl', `n_pl_avgs')
		
		if `n_pl_used'>`default_max_n_pl'{
			di _n "The number of placebo averages used (`=`n_pl_used'') is more than the default max (`default_max_n_pl') so computation will be slow. "
			if "`ci'"!=""{
				di " Additionally, with option -, ci- the whole distribution must be saved which can cause memory issues."
				di " Consider omitting -, ci- and/or -, n_pl_avgs()-." _n
			}
			else {
				di " Consider omitting -, n_pl_avgs()-." _n
			}
		}
	}
	local marg_draws = cond(`n_pl_used'!=`n_pl', `n_pl_used',.)
	di _n "Conducting inference: `num_steps' steps, and " `n_pl_used' " placebo averages"

	*Raw Estimates
	if "`ci'"!=""{
		di "Step 1 (3 substeps): a..." _continue
		mata: do_effect_avgs = get_avgs(do_effects_p, `marg_draws')
		di " b..." _continue
		mata: st_matrix("`pvals'", get_p_vals(tr_effect_avg, do_effect_avgs))
		di " c..." _continue
		mata: st_matrix("`CI'", get_CIs(tr_effect_avg, do_effect_avgs, strtoreal(st_global("S_level"))))
		mat rownames `CI' = ll ul
		mat colnames `CI' = `leadlist'
	}
	else {
		di "Step 1..." _continue
		mata: st_matrix("`pvals'", get_p_val_full(tr_effect_avg, do_effects_p, `marg_draws'))
	}
	mat colnames `pvals' = `leadlist'
	di " Finished"
	
	di "Step 2..." _continue
	mata: st_numscalar("`pval_post_RMSPE'", get_p_val_full(mean(tr_post_rmspes), do_post_rmspes_p, `marg_draws')[1,1])
	di " Finished"
	
	*Standardized effects
	di "Step 3..." _continue
	mata: st_matrix("`pvals_t'", get_p_val_full(tr_t_effect_avg, do_t_effects_p, `marg_draws'))
	mat colnames `pvals_t' = `leadlist'
	di " Finished"
	
	di "Step 4..." _continue
	mata: st_numscalar("`pval_post_RMSPE_t'", get_p_val_full(tr_post_rmspes_t_avg, do_post_rmspes_t_p, `marg_draws')[1,1])
	di " Finished"
	
	*Diagnostics
	di "Step 5..." _continue
	mata: st_numscalar("`pval_pre_RMSPE'", get_p_val_full(mean(tr_pre_rmspes), do_pre_rmspes_p, `marg_draws')[1,1])
	di " Finished"
	*Validation period RMSPE
	if `training_propr'>0{
		di "Step 6..." _continue
		mata: st_numscalar("`pval_val_RMSPE'", get_p_val_full(mean(st_matrix("`tr_val_rmspes'")), do_val_rmspes_p, `marg_draws')[1,1])
		di " Finished"
	}
	
	*Post output
	di _n "Post-treatment results: Effects, p-values, standardized p-values"
	mat `disp_mat' = (`estimates'', `pvals'[2,1...]',`pvals_t'[2,1...]')
	mat colnames `disp_mat' = estimates pvals pvals_std
	mat rownames `disp_mat' = `leadlist'
	matlist `disp_mat'
	*Effects
	ereturn post `estimates'
	ereturn local cmd="synth_runner"
	*Could return avg_post_rmspe, avg_post_rmspe_t, estimates_t but these aren't very interpretable
	matrix rownames `out_ef' = `plist'
	ereturn matrix treat_control = `out_ef'
	
	*Helpers
	ereturn local depvar="`depvar'"
	ereturn local treat_type="`treat_type'"
	if "`treat_type'"=="single unit"{
		ereturn local trunit="`tt_trunit'"
	}
	if "`treat_type'"!="multiple periods"{
		ereturn local trperiod="`tt_trperiod'"
	}
	
	*Inference stats
	ereturn scalar n_pl = `n_pl'
	ereturn scalar n_pl_used = `n_pl_used'
	mat `p2' = `pvals'[2,1...]
	mat rownames `p2' = `D'
	ereturn matrix pvals = `p2'
	if "`ci'"!="" ereturn matrix ci = `CI'
	mat `p2' = `pvals_t'[2,1...]
	mat rownames `p2' = `D'
	ereturn matrix pvals_std = `p2'
	if "`pvals1s'"!=""{
		mat `p1' = `pvals'[1,1...]
		mat rownames `p1' = `D'
		ereturn matrix pvals_1s = `p1'
		mat `p1' = `pvals_t'[1,1...]
		mat rownames `p1' = `D'
		ereturn matrix pvals_std_1s = `p1'
	}
	ereturn scalar pval_joint_post = `pval_post_RMSPE'
	ereturn scalar pval_joint_post_std = `pval_post_RMSPE_t'
	
	if "`failed_o'"=="1"{
		mat colnames `failed_opt_targets' = tper unit
		ereturn matrix failed_opt_targets = `failed_opt_targets'
	}
	
	*Diagnostics stats
	ereturn scalar avg_pre_rmspe_p = `pval_pre_RMSPE'
	if `training_propr'>0{
		ereturn scalar avg_val_rmspe_p = `pval_val_RMSPE'
	}
	
	cleanup_mata, tr_table(`uniq_trs') pre_limit_mult(`pre_limit_mult')
	
	if "`gen_vars'"!=""{
		qui merge 1:1 `pvar' `tvar' using "`keep'", nogenerate nolabel nonotes
		gen `depvar'_synth = `depvar' - effect
		if "`trends'"!="" {
			gen `depvar'_scaled_synth = `depvar'_scaled - effect_scaled
		}
	}
end

program def synth_runner_version, rclass
	di as result "synth_runner" as text " Stata module for running Synthetic Control estimations"
	di as result "version" as text " 1.6.0 "
	* List the "roles" (see http://r-pkgs.had.co.nz/description.html and http://www.loc.gov/marc/relators/relaterm.html)
	di as result "author" as text " Brian Quistorff [cre,aut]"
	
	return local version = "1.6.0"
end

//allows body or appendage to be null (so that looping and adding is easy)
//makes files even if inputs are 0-observation files
program append_to
	syntax, appendage(string) body(string)
	preserve
	
	drop _all
	cap use "`body'"
	cap append using `"`appendage'"'
	save "`body'", replace emptyok
end

program cleanup_mata
	syntax , tr_table(name) pre_limit_mult(string) [ warn ]

	local plain_mata_objs = "do_effect_avgs tr_pre_rmspes tr_post_rmspes do_post_rmspes_t_p " + ///
		"tr_t_effect_avg do_pre_rmspes_p do_effects_p tr_effect_avg " + ///
		"do_val_rmspes_p tr_effects do_t_effects_p do_post_rmspes_p tr_post_rmspes_t_avg"
	foreach mata_obj of local plain_mata_objs{
		mata: st_local("found", st_local("found")+(rows(direxternal("`mata_obj'"))?"yes":""))
		mata: rmexternal("`mata_obj'")
	}
	
	if `pre_limit_mult'!=.{
		mata: st_local("found", st_local("found")+(rows(direxternal("good_enough_ind"))?"yes":""))
		mata: rmexternal("good_enough_ind")
	}
	
	local num_tpers = rowsof(`tr_table')
	local per_tper_mata_objs "do_post_rmspe_t_base do_effect_base do_t_effect_base do_pre_rmspe_base do_post_rmspe_base do_val_rmspe_base"
	forval i=1/`num_tpers'{
		foreach mata_obj of local per_tper_mata_objs{
			mata: st_local("found", st_local("found")+(rows(direxternal("`mata_obj'`i'"))?"yes":""))
			mata: rmexternal("`mata_obj'`i'")
		}
		if `pre_limit_mult'!=.{
			local times =`tr_table'[`i',2]
			forval j=1/`times'{
				foreach mata_obj of local per_tper_mata_objs{
					mata: st_local("found", st_local("found")+(rows(direxternal("`mata_obj'`i'_`j'"))?"yes":""))
					mata: rmexternal("`mata_obj'`i'_`j'")
				}
			}
		}
	}
	if "`warn'"!="" & "`found'"!="" di as err "-synth_runner- will overwrite mata objects (ignore if we didn't cleanup after a previous run): `plain_mata_objs'; and numbered `per_tper_mata_objs'"
end




program load_dta_to_matrix
	syntax, dta(string) matrix(string)
	
	preserve
	qui use "`dta'", clear
	mkmat *, matrix(`matrix')
end

*Simple program to load a numeric dta into a mata variable
program load_dta_to_mata
	syntax, dta(string) mata_var(string)
	
	preserve
	qui use "`dta'", clear
	mata: `mata_var'=st_data(.,.)
end

*takes a synth keep() file and makes it into "effects" diffs (or standardized effects)
* standardizes lengths and then makes wide.
program cleanup_and_convert_to_diffs
	syntax, dta(string) out_effect(string) depvar(string) tper_var(string) max_lead(int) ///
		[out_effect_full(string) trends min_lead(int -1) pre_rmspe_max(numlist max=1 >0)] 
	_sr_get_returns pvar=r(panelvar) tvar=r(timevar) : tsset, noquery
	preserve
	
	keep `depvar' `pvar' `tvar'
	qui merge 1:1 `pvar' `tvar' using "`dta'", keep(match using) nogenerate
	
	//generate leads. CGNP13 define lead1 as contemporaneous (rather than lead0)
	//gen long lead = `tvar'-`tper_var'+1 //if time periods are only one apart
	qui bys `pvar': gen n_of_trperiod = _n if `tvar'==`tper_var' //in v12 leaving merge it's not sorted
	qui by `pvar': egen n_of_trperiod_all = max(n_of_trperiod)
	by `pvar': gen lead = _n - n_of_trperiod_all +1
	drop n_of_trperiod n_of_trperiod_all
	
	gen effect = `depvar'-`depvar'_synth
	if "`trends'"!=""{
		gen effect_scaled = `depvar'_scaled-`depvar'_scaled_synth
	}
	
	if "`out_effect_full'"!=""{
		tempfile int
		qui save "`int'"
		if "`trends'"!=""{
			qui replace `depvar'       = `depvar'_scaled
			qui replace `depvar'_synth = `depvar'_scaled_synth
		}
		qui drop if lead > `max_lead' | lead < `min_lead'
		collapse (mean) `depvar' `depvar'_synth, by(lead)
		sort lead
		mkmat `depvar' `depvar'_synth, matrix(`out_effect_full')
		qui use "`int'", clear
	}
	
	drop `depvar' `tper_var' `depvar'*_synth //will have already, redundant, redundant
	qui compress
	qui save "`dta'", replace
	
	if "`trends'"!=""{ //now the main effect is the scaled one
		drop effect
		rename effect_scaled effect
	}
	drop `tvar'
	keep `pvar' lead effect
	qui drop if lead > `max_lead' | lead < 1 /*`min_lead'*/ //for now just deal in post-periods (would have to rework to split matrices)
	qui reshape wide effect, i(`pvar') j(lead)
	//don't leave around globals from our reshape
	global ReS_Call
	global ReS_jv2
	drop `pvar' //for now don't need
	qui compress
	qui save "`out_effect'", replace
end


mata:

//ADH10 add 1 to the numerator and denominator of p-value fractions. (CGNP13 do not.)
//It depends on whether you (do|do not) you think the actual test is one of 
// the possible randomizations (usually with bootstraps you add one to the denominator).
real matrix get_p_vals(real rowvector tr_avg, real matrix do_avgs){
	T1 = cols(tr_avg)
	n_avgs = rows(do_avgs)

	pvals_s = J(2,T1,.)
	for(t=1; t<=T1; t++){
		if(sign(tr_avg[1,t])>0)
			pvals_s[1,t] = sum(    tr_avg[1,t] :<=    do_avgs[.,t] )/n_avgs
		else
			pvals_s[1,t] = sum(    tr_avg[1,t] :>=    do_avgs[.,t] )/n_avgs
		
		pvals_s[2,t] =   sum(abs(tr_avg[1,t]):<=abs(do_avgs[.,t]))/n_avgs //more common approach
		//pvals_s[2,t] = pvals_s[1,t]:*2 //Ficher 2-sided p-vals
	}
	return(pvals_s)
	
}

//Calculate the 2-sided Confidence Intervals
/* 
	
	* Note that if 0 not in [low_effect,high_effct]
	* then the Confidence Interval won't contain the estimated beta.
	* This is likely with only a few permutation tests.
	
	 * Testing non-null hypotheses of alpha0!=0: 
 * 		Apply null hypothesis (get "unexpected deviation") then permuate.
 * 		In this case, compare (alpha_hat-b0) to {alpha_perm}
 * This means that we take the level-bounds of the null then "flip it around bhat"
 * To make the math a bit nicer, I will reject a hypothesis if pval<=alpha
 * CI: Find all alpha0 that aren't rejected
 *		pval(alpha_hat=alpha0)>alpha
	
 */
real matrix get_CIs(real rowvector tr_avg, real matrix do_avgs, real scalar level){
	T1 = cols(tr_avg)
	n_avgs = rows(do_avgs)
	CIs = J(2,T1,.)
	//We might not have enough precision to get alpha, so figure out what we can get
	alpha = (100-level)/100
	p2min = 2/n_avgs
	alpha_ind = max((1,round(alpha/p2min)))
	alpha = alpha_ind * p2min
	//Find the CIs
	for(t=1;t<=T1; t++){
		sorted = sort(do_avgs[.,t],1)
		low_effect = sorted[alpha_ind]
		high_effect = sorted[(n_avgs+1)-alpha_ind]
		CIs[.,t] = (tr_avg[1,t] - high_effect\ tr_avg[1,t] - low_effect) 
		//note that the "swap" (high_effect used to define lower bound)
	}
	return(CIs)
	//could return alpha too
}

/* get_avgs+get_p_vals but without keeping around all the do_avgs*/
real matrix get_p_val_full(real rowvector tr_avg, pointer colvector do_aggs ,| real scalar n_draws){
	G = rows(do_aggs)
	T1 = cols(*do_aggs[1])
	do_picks = ( J(G-1,1,1)\ 0 )
	
	avg_set = J(G   , T1,.)
	tops = J(G, 1, .)
	N_PL = 1
	for(g=1; g<=G; g++){
		J_g = rows(*do_aggs[g])
		tops[g,1] = J_g
		N_PL = N_PL*J_g
	}
	randomizing = (!missing(n_draws) & n_draws<N_PL)
	n_avgs = (randomizing ? n_draws : N_PL )
	pvals_s = J(2,T1,0)
	//possibly faster to do if outside for (smart compilers can do this automatically)
	for(i=1; i<=n_avgs; i++){
		do_picks = (randomizing ? ran_index(tops) : inc_index(tops, do_picks))
		for(g=1; g<=G; g++){
			avg_set[g,.] = (*do_aggs[g,1])[do_picks[g,1],.]
		}
		do_avgs = mean(avg_set)
		
		for(t=1; t<=T1; t++){
			if(sign(tr_avg[1,t])>0)
				pvals_s[1,t] = pvals_s[1,t] + (    tr_avg[1,t] :<=    do_avgs[1,t] )
			else
				pvals_s[1,t] = pvals_s[1,t] + (    tr_avg[1,t] :>=    do_avgs[1,t] )
			
			pvals_s[2,t] =   pvals_s[2,t] + (abs(tr_avg[1,t]):<=abs(do_avgs[1,t])) //more common approach
			//pvals_s[2,t] = pvals_s[1,t]:*2 //Ficher 2-sided p-vals
		}
	}
	
	pvals_s = (pvals_s :/n_avgs)
	return(pvals_s)
}

real matrix get_avgs(pointer colvector do_aggs ,| real scalar n_draws){
	G = rows(do_aggs)
	T1 = cols(*do_aggs[1])
	do_picks = ( J(G-1,1,1)\ 0 )
	
	avg_set = J(G   , T1,.)
	tops = J(G, 1, .)
	N_PL = 1
	for(g=1; g<=G; g++){
		J_g = rows(*do_aggs[g])
		tops[g,1] = J_g
		N_PL = N_PL*J_g
	}
	randomizing = (!missing(n_draws) & n_draws<N_PL)
	n_avgs = (randomizing ? n_draws : N_PL )
	do_avgs = J(n_avgs, T1,.)

	//cleaner to put if in loop, but that would probably be much slower
	if(randomizing){
		for(i=1; i<=n_avgs; i++){
			do_picks = ran_index(tops)
			
			for(g=1; g<=G; g++){
				avg_set[g,.] = (*do_aggs[g,1])[do_picks[g,1],.]
			}
			do_avgs[i,.] = mean(avg_set)
		}
	}
	else {
		for(i=1; i<=n_avgs; i++){
			do_picks = inc_index(tops, do_picks)
			
			for(g=1; g<=G; g++){
				avg_set[g,.] = (*do_aggs[g,1])[do_picks[g,1],.]
			}
			do_avgs[i,.] = mean(avg_set)
		}
	}
	return(do_avgs)
}

/* In Stata 14 could replace this with runiformint(1, 1, J(G, 1, 1), tops) */
real colvector ran_index(real colvector tops, |real colvector picks){
	G = rows(tops)
	return(floor((runiform(G,1) :* tops)+J(G,1,1)))
}

real colvector inc_index(real colvector tops, real colvector picks){
	G = rows(picks)
	for(g=G; g>=1; g--){
		picks[g,1] = picks[g,1]+1
		if(picks[g,1]<=tops[g])
			break
		picks[g,1]=1
	}
	return(picks)
}

end
