*Override the PERSONAL (so that -ado dir-, -adoupdate-, and -ssc uninstall- work)
*  this is better than setting the env var S_ADO
*Could put this in a .profile in the root, but want this to work interactively on Windows.
sysdir set PERSONAL "`c(pwd)'/code/ado"
sysdir set PLUS "`c(pwd)'/code/ado" //some commands think this has to be in S_ADO
global S_ADO "PERSONAL;BASE"
* adostorer install synth, adofolder(code/ado) all mkdirs
* adostorer install parallel, adofolder(code/ado) all mkdirs from(C:\Users\bquist\Documents\GitHub\parallel)
platformname
global S_ADO "PLUS;BASE;code/ado/`r(platformname)'"
net set ado PERSONAL
net set other PERSONAL
mata: mata mlib index
