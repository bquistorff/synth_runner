*! version 1.0 Brian Quistorff
*! Produces p-value graphs for post-treatment per-period effects
program pval_graphs
	version 12 //haven't tested on earlier versions
	syntax [, pvals_gname(string) pvals_std_gname(string) xtitle(string) ytitle(string) ///
		pvals_options(string) pvals_std_options(string)]
	
	_assert "`e(cmd)'"=="synth_runner", msg("Need to run this after -synth_runner- (with no other estimation routines in between).")
	if "`pvals_gname'"=="" local pvals_gname pvals
	if "`pvals_std_gname'"=="" local pvals_std_gname pvals_std
	if "`xtitle'"=="" local xtitle "Number of periods after event (Leads)"
	if "`ytitle'"=="" local ytitle "Probability that this would happen by chance"
	preserve
	drop _all
	tempname comb_mat
	mat `comb_mat' = e(pvals)' , e(pvals_std)'
	qui svmat `comb_mat', names(p)
	rename (p1 p2) (pvals pvals_std)
	gen int lead = _n
	local N = _N

	foreach ptype in pvals pvals_std{
		twoway (scatter `ptype' lead), name(``ptype'_gname', replace) ///
			plotregion(margin(zero)) xlabel(1(1)`N') xscale(r(0 `=`N'+1')) ///
			ylabel(0(0.1)1) xtitle("`xtitle'") ///	
			ytitle("`ytitle'") ``ptype'_options'
	}

end
