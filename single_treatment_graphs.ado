*! version 1.0 Brian Quistorff <bquistorff@gmail.com>
*! Produces graphs for all units: raw outcome data, and effects
*! Only possible with settings where 1 period of treatment
program single_treatment_graphs
	version 12 //haven't tested on earlier versions
	syntax , depvar(string) trperiod(int) trunit(string) ///
		[effect_var(string) raw_gname(string)  effects_gname(string) ///
		do_color(string) effects_ylabels(string) effects_ymax(string) effects_ymin(string)]

	if "`do_color'"=="" local do_color background
	if "`effect_var'"=="" local effect_var effect
	if "`raw_gname'"=="" local raw_gname raw
	if "`effects_gname'"=="" local effects_gname effects

	tsset, noquery
	local pvar = "`r(panelvar)'"
	local tvar = "`r(timevar)'"

	qui levelsof `pvar', local(units)
	local n_units : list sizeof units
	local n_whole_chunks = int(`n_units'/10)
	forval i=1/`n_whole_chunks'{
		local n1 = (`i'-1)*10+1
		local n2 = `i'*10
		local raw_gline    "`raw_gline' (line `depvar'`n1'-`depvar'`n2' `tvar', lpattern(solid..) lcolor(`do_color'..))"
		local effect_gline "`effect_gline' (line `effect_var'`n1'-`effect_var'`n2'  `tvar', lpattern(solid..) lcolor(`do_color'..))" 
	}
	local n1 = `n_whole_chunks'*10+1
	local n2 = `n_units'
	local raw_gline    "`raw_gline' (line `depvar'`n1'-`depvar'`n2' `tvar', lpattern(solid..) lcolor(`do_color'..))"
	local effect_gline "`effect_gline' (line `effect_var'`n1'-`effect_var'`n2'  `tvar', lpattern(solid..) lcolor(`do_color'..))" 

	local ylbl : variable label `depvar'
	
	preserve
	keep `pvar' `tvar' `depvar'
	qui reshape wide `depvar', i(`tvar') j(`pvar') //easier in wide format
	twoway `raw_gline' (line `depvar'`trunit' `tvar', lpattern(solid..) lstyle(foreground..)), ///
		xline(`=`trperiod'-1') name(`raw_gname', replace) legend(order(`=`n_units'+1' "Treated" 1 "Donors")) ///
		ylabel(, nogrid) ytitle("`ylbl'")
	restore

	*The effects graph
	*This graph is hard to reproduce as Stata doesn't like to omit any data, so clipping the y-bounds isn't easy. 
	* (yscale can only extend the y-range)
	* Could create a censored version of effect with missing if outside of bounds, 
	* but then partial connecting lines won't go to/from those outliers, so looks weird.
	* Instead, use -gr_edit- and directly edit the class properties. 
	* This shortens the y-scale but lines are drawn then outside of the plotregion. 
	* So make the line color the same as the background color so they aren't visible.
	preserve
	keep `tvar' `pvar' `effect_var'
	qui reshape wide `effect_var', i(`tvar') j(`pvar') //easier in wide format
	*there is a graph option limit of 20 so limit the number per line
	twoway `effect_gline'	(line `effect_var'`trunit' `tvar', lstyle(foreground..)), ///
		xline(`=`trperiod'-1') name(`effects_gname', replace) ylabel(`effects_ylabels', nogrid) ///
			legend(order(`=`n_units'+1' "Treated" 1 "Donors")) ytitle("Effects - `ylbl'")
	if "`effects_ymax'"!="" gr_edit .plotregion1.yscale.curmax=`effects_ymax'
	if "`effects_ymin'"!="" gr_edit .plotregion1.yscale.curmin=`effects_ymin'
	restore
end
