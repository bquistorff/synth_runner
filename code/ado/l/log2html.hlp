{smcl}
{* 8jun2006}{...}
{hline}
help for {hi:log2html}{right:SSC distribution 8 June 2006}
{hline}

{title:Translate a SMCL log file into HTML}

{p 8 17 2}{cmd:log2html} 
{it:smclfile}
[{cmd:,} 
{cmd:replace} 
{cmd:erase} 
{cmdab:ti:tle}{cmd:(}{it:string}{cmd:)}
{cmdab:line:size(}{it:#}{cmd:)}{break} 
{cmdab:per:centsize(}{it:integer}{cmd:)}
{cmd:bold}{break}
{cmdab:sch:eme}{cmd:(}{it:string}{cmd:)}
{cmd:css(}{it:string}{cmd:)}{break}		
{cmdab:in:put}{cmd:(}{it:string}{cmd:)} 
{cmdab:r:esult}{cmd:(}{it:string}{cmd:)} 
{cmdab:err:or}{cmd:(}{it:string}{cmd:)} 
{cmdab:te:xt}{cmd:(}{it:string}{cmd:)} 
{cmd:bg(}{it:string}{cmd:)} 
] 


{title:Description}

{p 4 4 2}{cmd:log2html} translates Stata log files or other 
files in SMCL to HTML. 

{title:Remarks}

{p 4 4 2}{cmd:log2html} is primarily for use after {cmd:log}; see {help log}.

{p 4 4 2}{cmd:log2html} makes use of an undocumented command in Stata version 7
up, {cmd:log html}, which generates HTML files from SMCL (e.g. log) files.
SMCL, the Stata Markup and Control Language {help smcl}, is the default log
file format introduced with version 7, and contains markup (similar to HTML)
around elements of the log file. To use {cmd:log2html} on log files, you must 
first generate the default SMCL log file, not a text log file, with the file 
extension {cmd:.smcl}.  Thus if you have {cmd:set logtype text} to prevent the 
generation of SMCL log files, you must either turn it off or explicitly state 
that a SMCL log file is to be produced, as by {cmd: log using my.smcl}. 

{p 4 4 2}{cmd:log2html} requires only the base name of a logfile: 
e.g. {cmd:my}, if the logfile is named {cmd:my.smcl}. The name of the HTML file
produced will be this base name with {cmd:.html} appended, e.g. {cmd:my.html}.

{p 4 4 2}{cmd:log2html} requires Stata version 8 at least. 

{p 4 4 2}{cmd:loghtml} produces a complete HTML page (i.e. with <HTML> and
<BODY> tags).  By default, the page will have a white background; input lines
(those resulting from user input) are rendered in RGB color "CC6600" (a shade
of brown); and highlighted result-window lines are rendered in RGB color
"000099" (a shade of blue).  The options permit other choices for these three
colors. For best results, one of the 216 "web safe" colors that display
properly in web browsers on all computers in 256-color mode should be used.
Also note that some combinations of colors are not workable; e.g. a black
("000000") background will cause all normally-rendered text to disappear.

{p 4 4 2}Colors are specified as hexadecimal RGB colors ranging from 000000
(black) to FFFFFF (white),  where FF0000 is red, 00FF00 is green, and 0000FF is
blue. It is best to use web-safe colors, where both digits of each color pair
match and are divisible by 3 (i.e. 00 33 66 99 CC or FF).
 
{p 4 4 2}Those wanting to include the CSS classes used by {cmd:log2html} should
make an HTML file with the CSS option, and then look at the resulting
page in a text editor. It will give more insight than any explanation here
could give.


{title:Options}

{p 4 8 2}{cmd:replace} specifies that if the HTML file exists, it is to be
replaced.

{p 4 8 2}{cmd:erase} specifies that the SMCL log file is to be erased (deleted)
after processing.
 
{p 4 8 2}{cmd:title()} specifies a string to be placed in the <TITLE> of the
HTML page, and on the first line of the body of the page, using a <H2>
heading.

{p 4 8 2}{cmd:linesize()} specifies a maximum line size for the result, 
i.e. the width in characters of rendered HTML lines. The argument
must be between 40 and 255 inclusive. Default is the current linesize. 

{p 4 4 2}The remaining options pertain to setting how the HTML page will appear
when rendered in a browser.
 
{p 4 8 2}{cmd:percentsize()} specifies the scaling of the font to be used on
the resulting HTML page as a percentage of the default. (The
actual size is not specified, since it is typically specified by
the person using the browser, not the person sharing the
information.) This affects all text on the page.

{p 4 8 2}{cmd:bold} specifies that input lines (those resulting from
user input), results from Stata, and error numbers be displayed as
bold text.

{p 4 8 2}{cmd:scheme()} is the simplest way to change the colors of the
resulting web page. The allowable schemes are

{p 8 10 12}{cmd:black}, {cmd:white}, or {cmd:blue}, which correspond closely 
to the colors of Stata's color schemes for the results window.

{p 8 10 12}{cmd:yellow}, which makes an easy-on-the-eyes page with
a faint yellow background.

{p 4 8 2}{cmd:input()}, {cmd:result()}, {cmd:text()}, and {cmd:error()} can be
used independently to set the foreground color of the text which corresponds to
user input, Stata results, plain text output, and error numbers. 

{p 4 8 2}{cmd:bg()} specifies the color of the background of the
page. For convenience, this can be given as "grey" or "gray".

{p 4 8 2}{cmd:css()} specifies the cascading style sheet for the web
page. This is an advanced option for people who use CSS for 
standardizing the appearance of their web sites. If you do not know
what CSS means, there is no need to worry: if this option is
omitted, {cmd:log2html} will put the proper information into the
HTML file it creates.


{title:Examples}

{p 4 8 2}{inp:. log using autostudy, replace}{p_end}
{p 4 8 2}{inp:. use auto}{p_end}
{p 4 8 2}{inp:. desc}{p_end}
{p 4 8 2}{inp:. summ}{p_end}
{p 4 8 2}{inp:. regress price mpg rep78}{p_end}
{p 4 8 2}{inp:. log close}

{p 4 8 2}{inp:. log2html autostudy, replace}

{p 4 8 2}{inp:. log2html autostudy, replace ti(Automobile study)}

{p 4 8 2}{inp:. log2html autostudy, replace ti(Automobile study) scheme(black)}

{p 4 8 2}{inp:. log2html autostudy, replace in(ff3300) res(003333) bg(grey)}

{p 4 8 2}{inp:. log2html autostudy, replace ti(Automobile study) css("./mystyles.css")}


{title:References}

{p 4 4 2}Priester, Gary W. 2000. All you need to know about web safe colors.{break} 
{browse "http://www.webdevelopersjournal.com/articles/websafe1/websafe_colors.html"}{p_end}
      
{p 4 4 2}Richmond, Alan. Introduction to style sheets.{break}
{browse "http://www.wdvl.com/Authoring/Style/Sheets/Tutorial.html"}{p_end}


{title:Acknowledgements}

       {p 4 4 2}Ken Higbee helped with the documentation
       of {cmd:log html} and made suggestions for improvement of this routine.
       Renzo Comolli drew our attention to problems arising with long lines 
       and quoted filenames. Friedrich Huebler also raised the issue of 
       line size and Alan Riley and Joseph Coveney showed how to tackle it. 
 

{title:Authors} 

        {p 4 4 2}Christopher F Baum, Boston College, USA{break} 
        baum@bc.edu{p_end}
        
        {p 4 4 2}Nicholas J. Cox, Durham University, UK{break} 
        n.j.cox@durham.ac.uk{p_end}

        {p 4 4 2}Bill Rising, Bellarmine University, USA{break}
	wrising@bellarmine.edu{p_end}


{title:Also see} 

{p 4 13 2}Manual:  {hi:[R] log}, {hi:[P] smcl}

{p 4 13 2}On-line:  help for {help log}, {help smcl} 

