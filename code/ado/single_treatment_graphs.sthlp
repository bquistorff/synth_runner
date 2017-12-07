{smcl}
{* 17feb2017}{...}
{vieweralsosee "synth_runner" "help synth_runner"}{...}
{vieweralsosee "effect_graphs" "help effect_graphs"}{...}
{vieweralsosee "pval_graphs" "help pval_graphs"}{...}
{cmd:help single_treatment_graphs} 
{hline}

{title:Title}

{p2colset 5 32 32 2}{...}
{p2col :{hi:single_treatment_graphs} {hline 2}}Some graphs for single treatment period estimations to be run after synth_runner. {p_end}
{p2colreset}{...}


{title:Syntax}

{p 6 8 2}
{opt single_treatment_graphs} [, {opt scaled} {opt raw_gname:(string)} 
{opt effects_gname:(string)} {opt trlinediff:(real -1)} {opt do_color:(string)} {opt effects_ylabels:(string)} {opt effects_ymax:(string)} {opt effects_ymin:(string)} 
{opt treated_name:(string)} {opt donors_name:(string)} {opt effects_ytitle:(string)} {opt raw_options:(string)} {opt effects_options:(string)} ]

{p 4 4 2}
Creates two graphs when there is a single unit that has been treated. The first graphs the outcome path of all units while the second graphs the prediction differences for all units.


{title:Options}
{p 4 8 2}
{cmd:scaled} if {cmd:synth_runner} was estimated using {it:scaled} then this can be specified to produce graphs from the {it:scaled} (rather than unscaled) values. 

{p 4 8 2}
{cmd:do_color} specifies a dolor for the donor lines. The default is theme's "bg" (background) color. 

{p 4 8 2}
{cmd:trlinediff} specifies the offset of a vertical treatment line from the first treatment period. Likely options include values in the range from (first treatment period - last post-treatment period) to 0 and the default value is -1. 

{p 4 8 2}
{cmd:effects_ymax}, {cmd:effects_ymin}, and {cmd:effects_ylabels} allow customization of the y-axis display for the effects graph. {cmd:effects_ymax} and {cmd:effects_ymin} optionally specify the maximum range to show for the y-axis. 
{cmd:effects_ylabels} specifies the labels to be displayed.

{p 4 8 2}
{cmd: raw_gname} and {cmd:effects_gname} can be used to specify names for the raw and effects graphs respectively. The defaults are "raw" and "effects".

{p 4 8 2}
{cmd: treated_name} and {cmd:donors_name} can be used to override defaults for the legend on the graphs. The defaults are "Treated" and "Donors" respectively.

{p 4 8 2}
{cmd:raw_ytitle} and {cmd: effects_ytitle} are used to override the default {it:ytitle} option to {cmd:graph twoway} for the raw and effects graphs respectively. 
The default for {it:raw_ytitle} is the label for {it:depvar} if that is supplied. 
The default for {it:effect_ytitle} is "Effect - " plus the {it:ytitle} of the raw graph.

{p 4 8 2}
{cmd: raw_options} and {cmd: effects_options} allow additional options to be specified for the raw and effects graphs respectively. These will be added as extra options to the {cmd:graph twoway} call. 
For example, {cmd:raw_options(title("My graph"))} will specify a title for the raw graph.
