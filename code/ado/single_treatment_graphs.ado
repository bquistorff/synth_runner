*! version 1.0 Brian Quistorff
*! Produces graphs for all units: raw outcome data, and effects
program single_treatment_graphs
	version 12 //haven't tested on earlier versions
	syntax , [scaled raw_gname(string)  effects_gname(string) trlinediff(real -1) ///
		do_color(string) effects_ylabels(string) effects_ymax(string) effects_ymin(string) clip_mode(string) ///
		treated_name(string) donors_name(string) raw_ytitle(string) effects_ytitle(string) raw_options(string) effects_options(string)]

	_assert "`e(cmd)'"=="synth_runner", msg("Need to run this after -synth_runner- (with no other estimation routines in between).")
	_assert "`e(treat_type)'"=="single unit", msg("Can only be run after estimation with a single treated unit")
	if "`do_color'"=="" local do_color bg
	if "`raw_gname'"=="" local raw_gname raw
	if "`effects_gname'"=="" local effects_gname effects
	if "`treated_name'"=="" local treated_name "Treated"
	if "`donors_name'"=="" local donors_name "Donors"
	
	local clip_mode_msg "clip_mode option is either 'drop', 'keep', or a pair of numbers bounding the values above and below the plot region extent"
	_assert `: list sizeof clip_mode'<=2, msg("`clip_mode_msg'")
	if `: list sizeof clip_mode'==2{
		gettoken ymax_extra ymin_extra : clip_mode
	}
	else{
		if "`clip_mode'"=="" & "`effects_ymax'"!="" & "`effects_ymin'"!=""{
			local available = cond("`effects_ymax'"!="" & "`effects_ymin'"!="",`effects_ymax'-`effects_ymin',0)
			local ymax_extra = 0.07*`available'
			local ymin_extra = 0.30*`available'
		}
		else {
			_assert inlist("`clip_mode'", "drop", "keep", ""), msg("`clip_mode_msg'")
		}
	}

	local depvar = cond("`scaled'"=="", "`e(depvar)'", "`e(depvar)'_scaled")
	confirm variable `depvar'
	local effect_var = cond("`scaled'"=="", "effect", "effect_scaled")
	cap confirm variable `effect_var'
	_assert _rc==0, msg(`"Effect variable [`effect_var'] does not exist, did you use the -, gen_vars- option in -synth_runner-?"') rc(111)
	local trunit="`e(trunit)'"
	local trperiod=`e(trperiod)'
	tsset, noquery
	local pvar = "`r(panelvar)'"
	local tvar = "`r(timevar)'"

	qui levelsof `pvar', local(units)
	local n_units : list sizeof units
	local n_whole_chunks = int(`n_units'/10)
	forval i=1/`n_whole_chunks'{
		local ind1 = (`i'-1)*10+1
		local ind2 = `i'*10
		local n1 : word `ind1' of `units'
		local n2 : word `ind2' of `units'
		local raw_gline    "`raw_gline' (line `depvar'`n1'-`depvar'`n2' `tvar', lpattern(solid..) lcolor(`do_color'..))"
		local effect_gline "`effect_gline' (line `effect_var'`n1'-`effect_var'`n2'  `tvar', lpattern(solid..) lcolor(`do_color'..))" 
	}
	if `n_units'>`=`n_whole_chunks'*10' {
		local ind1 = `n_whole_chunks'*10+1
		local ind2 = `n_units'
		local n1 : word `ind1' of `units'
		local n2 : word `ind2' of `units'
		local raw_gline    "`raw_gline' (line `depvar'`n1'-`depvar'`n2' `tvar', lpattern(solid..) lcolor(`do_color'..))"
		local effect_gline "`effect_gline' (line `effect_var'`n1'-`effect_var'`n2'  `tvar', lpattern(solid..) lcolor(`do_color'..))" 
	}
	local ylbl : variable label `depvar'
	if "`raw_ytitle'"=="" local raw_ytitle "`ylbl'"
	if "`effects_ytitle'"=="" & "`raw_ytitle'"!="" local effects_ytitle "Effects - `ylbl'"
	
	preserve
	keep `pvar' `tvar' `depvar'
	qui reshape wide `depvar', i(`tvar') j(`pvar') //easier in wide format
	twoway `raw_gline' (line `depvar'`trunit' `tvar', lpattern(solid..) lstyle(foreground..)), ///
		xline(`=`trperiod'+`trlinediff'') name(`raw_gname', replace) legend(order(`=`n_units'+1' "`treated_name'" 1 "`donors_name'")) ///
		ylabel(, nogrid) ytitle("`raw_ytitle'") `raw_options'
	restore

	*The effects graph
	* The graph from JASA 2010 doesn't show the all the data (outliers extend beyond the plot region)
	* We offer some options here if you want to show a narrower y-range
	* 1) "drop" - We drop the data. This can cause disconnected lines.
	* 2) "keep" - Lines will extend beyond the plot region. 
	*    This is hard to do (Stata doesn't like to omit any data), but use -gr_edit- and directly edit the class properties. 
	*    This shortens the y-scale but lines are drawn then outside of the plotregion. 
	*    So make the line color the same as the background color so they aren't visible.
	*    This usually won't be a problem, but may cause issues with eps exports where the bounding box doesn't clip the contents
	* 3) "" or "X1 X2" - The idea is to manually truncate the data range so that it is manually controlled to the size of the box
	*    It's nice if the data looks like it shoots off screen, but can be between the edge of the plotregion and graph region.
	preserve
	keep `tvar' `pvar' `effect_var'
	if "`clip_mode'"=="drop"{
		if "`effects_ymax'"!="" replace `effect_var'=. if `effect_var'>`effects_ymax'
		if "`effects_ymin'"!="" replace `effect_var'=. if `effect_var'<`effects_ymin'
	}
	if "`ymax_extra'`ymin_extra'"!="" {
		if "`effects_ymax'"!="" replace `effect_var'=`effects_ymax'+`ymax_extra' if `effect_var'>`effects_ymax'+`ymax_extra'
		if "`effects_ymin'"!="" replace `effect_var'=`effects_ymin'-`ymin_extra' if `effect_var'<`effects_ymin'-`ymin_extra'
	}
	qui reshape wide `effect_var', i(`tvar') j(`pvar') //easier in wide format
	global ReS_Call
	global ReS_jv2
	*there is a graph option limit of 20 so limit the number per line
	twoway `effect_gline'	(line `effect_var'`trunit' `tvar', lstyle(foreground..)), ///
		xline(`=`trperiod'+`trlinediff'') name(`effects_gname', replace) ylabel(`effects_ylabels', nogrid) ///
			legend(order(`=`n_units'+1' "`treated_name'" 1 "`donors_name'")) ytitle("`effects_ytitle'") `effects_options'
	if "`effects_ymax'"!="" gr_edit .plotregion1.yscale.curmax=`effects_ymax'
	if "`effects_ymin'"!="" gr_edit .plotregion1.yscale.curmin=`effects_ymin'
	restore
end
