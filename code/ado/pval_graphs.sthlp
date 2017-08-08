{smcl}
{* 17feb2017}{...}
{vieweralsosee "synth_runner" "help synth_runner"}{...}
{vieweralsosee "effect_graphs" "help effect_graphs"}{...}
{vieweralsosee "single_treatment_graphs" "help single_treatment_graphs"}{...}
{cmd:help pval_graphs} 
{hline}

{title:Title}

{p2colset 5 22 22 2}{...}
{p2col :{hi:pval_graphs} {hline 2}}Some graphs for inference to be run after synth_runner. {p_end}
{p2colreset}{...}


{title:Syntax}

{p 6 8 2}
{opt pval_graphs} [, {opt pvals_gname:(string)} {opt pvals_std_gname:(string)} {opt xtitle:(string)} {opt ytitle:(string)} {opt pvals_options:(string)} 
{opt pvals_std_options:(string)} ]

{p 4 4 2}
Creates plots of the p-values per-period for post-treatment periods for both raw and standardized effects.


{title:Options}

{p 4 8 2}
{cmd: pvals_gname} and {cmd:pvals_std_gname} can be used to specify names for the plain and standardized graphs respectively. The defaults are "pvals" and "pvals_std".

{p 4 8 2}
{cmd: xtitle} is used to override the default {it:xtitle} option to {cmd:graph twoway}. The default is "Number of periods after event (Leads)".

{p 4 8 2}
{cmd: ytitle} is used to override the default {it:ytitle} option to {cmd:graph twoway}. The default is "Probability that this would happen by chance".

{p 4 8 2}
{cmd: pvals_options} and {cmd: pvals_std_options} allow additional options to be specified for the plain and standardized graphs respectively. These will be added as extra options to the {cmd:graph twoway} call. 
For example, {cmd:pvals_options(title("My graph"))} will specify a title for the plain graph.
