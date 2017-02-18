{smcl}
{* *! version 0.13.03  6mar2013}{...}
{cmd:help normalizepath}
{hline}

{title:Title}

{phang}
{bf:normalizepath} {hline 2} Stata module to parse (and normalize) files' paths

{title:Syntax}

{p 8 17 2}
{cmdab:normalizepath} {help filename}

{phang}

{title:Description}

{pstd}
{cmd:normalizepath} parses a filename and returns (in {help return:r()}) the file
name, extension, location (directory) and fullpath.{p_end}

{title:Examples}

{phang2}{cmd:. normalizepath ../myfile.dta}{p_end}
{phang2}{cmd:. normalizepath "~/thisfile.do"}{p_end}
{phang2}{cmd:. normalizepath thatfile.mata}{p_end}

{title:Saved results}

{pstd}
{cmd:normalizepath} saves the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Locals}{p_end}
{synopt:{cmd:r(myfile)}}Entered filename{p_end}
{synopt:{cmd:r(fullpath)}}Resulting fullpath{p_end}
{synopt:{cmd:r(fileext)}}File extension{p_end}
{synopt:{cmd:r(filedir)}}File location (directory){p_end}

{title:Author}

{pstd}
George Vega Yon, Superindentencia de Pensiones. {browse "mailto:gvega@spensiones.cl"}
{p_end}

{title:Also see}

{psee}{help mata pathjoin}, {help confirm}{p_end}

