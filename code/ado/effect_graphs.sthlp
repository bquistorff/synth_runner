{smcl}
{* 17feb2017}{...}
{vieweralsosee "synth_runner" "help synth_runner"}{...}
{vieweralsosee "pval_graphs" "help pval_graphs"}{...}
{vieweralsosee "single_treatment_graphs" "help single_treatment_graphs"}{...}
{cmd:help effect_graphs} 
{hline}

{title:Title}

{p2colset 5 22 22 2}{...}
{p2col :{hi:effect_graphs} {hline 2}}Some graphs for visualizing effects to be run after synth_runner. {p_end}
{p2colreset}{...}


{title:Syntax}

{p 6 8 2}
{opt effect_graphs} [ , {opt scaled} {opt trlinediff:(real -1)} 
{opt tc_gname:(string)} {opt effect_gname:(string)} {opt treated_name:(string)} {opt sc_name:(string)} {opt effect_ytitle:(string)} 
{opt tc_options:(string)} {opt effect_options:(string)} ]

{p 4 4 2}
Creates two graphs after {cmd:synth_runner} estimation. One plots the outcome for the unit and its synthetic control while the other plots the difference between the two (which for post-treatment is the "effect").


{title:Options}

{p 4 8 2}
{cmd:scaled} if {cmd:synth_runner} was estimated using {it:scaled} then this can be specified to produce graphs from the {it:scaled} (rather than unscaled) values.


{p 4 8 2}
{cmd:trlinediff} specifies the offset of a vertical treatment line from the first treatment period. Likely options include values in the range from (first treatment period - last post-treatment period) to 0 and the default value is -1.

{p 4 8 2}
{cmd:tc_gname} and {cmd:effect_gname} are used to override the default names of the graphs. The defaults are "tc" and "effect".

{p 4 8 2}
{cmd: treated_name} and {cmd:sc_name} can be used to override defaults for the legend on the Treatment-Control graph. The defaults are "Treated" and "Synthetic Control" respectively.

{p 4 8 2}
{cmd:tc_ytitle} and {cmd: effect_ytitle} are used to override the default {it:ytitle} option to {cmd:graph twoway} for the Treatment-Control and Effect graphs respectively. 
The default for {it:tc_ytitle} is the label for {it:depvar} if that is supplied. 
The default for {it:effect_ytitle} is "Effect - " plus the {it:ytitle} of the Treatment-Control graph.

{p 4 8 2}
{cmd: tc_options} and {cmd: effect_options} allow additional options to be specified for the Treatment-Control and Effect graphs respectively. These will be added as extra options to the {cmd:graph twoway} call. 
For example, {cmd:tc_options(title("My graph"))} will specify a title for the Treatment-Control graph.

