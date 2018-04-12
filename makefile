# Comments that begin with ## will be shown from target help
##Testing:
## source code/test_stata12_env.sh
## make tests
##Updating module dependencies:
## See code/setup_ado.do
##Release:
## make releasehelp
##Paper:
## make paper
## make check_paper
##SJ (automatically overwrites):
## make sj-deliverable

.PHONY: list help
help : 
	@echo "Output comments:"
	@echo
	@sed -n 's/^##//p' makefile
	@printf "\nList of all targets: "
	@$(MAKE) -s list

# List targets (http://stackoverflow.com/a/26339924/3429373)
list:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$' | xargs

.PHONY: sj-deliverable usage-cleanup usage-delete clean check_smcl check_version check gen_html_help releasehelp code_checks package_checks package check_paper


# get the list of eps files from
#. grepr eps writeups/synth_runner_sj.lyx | grep filename | cut -c14- | tr '\n' ' '
#code files that are not in the package: usage.do 
sj-deliverable:
	-rm deliverables/sj/*.zip
	sed 's|code/ado/||' synth_runner.pkg > deliverables/synth_runner.pkg
	zip -j deliverables/sj/figs.zip fig/eps/cigsale1_raw.eps fig/eps/cigsale1_effects.eps fig/eps/cigsale1_effect.eps fig/eps/cigsale1_tc.eps fig/eps/cigsale1_pval.eps fig/eps/cigsale1_pval_t.eps fig/eps/cigsale2_raw.eps fig/eps/cigsale2_effects.eps fig/eps/cigsale3_effect.eps fig/eps/cigsale3_tc.eps
	zip -j deliverables/sj/program_files.zip code/ado/_sr_add_keepfile_to_agg.ado code/ado/_sr_do_work_do.ado code/ado/_sr_do_work_tr.ado code/ado/_sr_gen_time_locals.ado code/ado/_sr_get_returns.ado code/ado/_sr_print_dots.ado code/ado/calc_RMSPE.ado code/ado/effect_graphs.ado code/ado/effect_graphs.sthlp code/ado/pval_graphs.ado code/ado/pval_graphs.sthlp code/ado/single_treatment_graphs.ado code/ado/single_treatment_graphs.sthlp code/ado/synth_runner.ado code/ado/synth_runner.sthlp deliverables/synth_runner.pkg code/ado/synth_wrapper.ado code/usage.do stata.toc
	cp writeups/synth_runner_sj.pdf deliverables/sj
	@echo "README.txt is already there"
	@echo "Check that including all figs (see command in makefile)"

sj-deliverable2:
	-rm deliverables/sj2/*.zip
	cp deliverables/sj/program_files.zip .
	cp deliverables/sj2/README.txt .
	zip deliverables/sj2/submission.zippy fig/eps/cigsale1_raw.eps fig/eps/cigsale1_effects.eps fig/eps/cigsale1_effect.eps fig/eps/cigsale1_tc.eps fig/eps/cigsale1_pval.eps fig/eps/cigsale1_pval_t.eps fig/eps/cigsale2_raw.eps fig/eps/cigsale2_effects.eps fig/eps/cigsale3_effect.eps fig/eps/cigsale3_tc.eps literature/_IDB_synth.bib writeups/synth_runner_sj.lyx writeups/synth_runner_sj.pdf writeups/sj.bst writeups/sj.sty writeups/stata.sty writeups/tl.pdf writeups/tr.pdf program_files.zip README.txt
	rm program_files.zip README.txt

usage-cleanup:
	-mv *.log log/do/
	-mv *.gph fig/gph/
	-mv *.eps fig/eps/
	-mv *.pdf fig/pdf/

usage-delete:
	-rm *.log
	-rm *.gph
	-rm *.eps
	-rm *.pdf
	
clean:
	-rm -f temp/*

check : code_checks package_checks

package_checks: check_version
	
inc_dist_date:
	sed -i "s/\(d Distribution-Date: \).\+/\1$$(date +%Y%m%d)/g" synth_runner.pkg

code_checks: check_smcl

package: inc_dist_date code/ado/synth_runner.html
  
#Smcl has problems displaying lines over 244 characters
check_smcl:
	@echo "Will display lines if error"
	-grep '.\{245\}' code/ado/synth_runner.sthlp
	-grep '.\{245\}' code/ado/effect_graphs.sthlp
	-grep '.\{245\}' code/ado/pval_graphs.sthlp
	-grep '.\{245\}' code/ado/single_treatment_graphs.sthlp
	@echo ""

check_version:
	@echo "Visually ensure numbers are the same:"
	grep Version code/ado/synth_runner.sthlp
	@echo
	grep Version synth_runner.pkg
	@echo
	@echo code/ado/synth_runner.ado
	@grep "! version" code/ado/synth_runner.ado
	@grep "local version" code/ado/synth_runner.ado
	@grep '"version" as' code/ado/synth_runner.ado
	@echo ""

releasehelp:
	@echo Make sure you run tests \(on Stata v12\)
	@echo -make code_checks-.
	@echo Help files consistent \(smcl, lyx, README.md\)
	@echo -make package- and bump the version.
	@echo -make package_checks-
	@echo Edit the CHANGELOG.md
	@echo Push to GitHub
	@echo Go to https://github.com/bquistorff/synth_runner/releases and make a release
	@echo Notify the release on https://github.com/bquistorff/synth_runner/issues/1

TESTS_DOS=usage.do test.do
TESTS_LOGS:= $(TESTS_DOS:.do=.log)

tests: 
	@echo Running tests. Do on Stata 12.
	@echo If error, search for "^r\(" in less: less code/all_tests_results.txt
	@echo Afterword, drag all PDFs to PDF viewer, then: make usage-delete or usage-cleanup
	export S_ADO="code/ado/;UPDATES;BASE;SITE;.;PERSONAL;PLUS;OLDPLACE" && $(STATABATCH) do code/export_platformname.do code/platformname.txt;
	PLAT=$$(<code/platformname.txt) && \
		export S_ADO="code/ado/;code/ado/$$PLAT;UPDATES;BASE;SITE;.;PERSONAL;PLUS;OLDPLACE" && \
		export STATATMP=. && \
		for i in $(TESTS_DOS) ; do \
			$(STATABATCH) do code/$${i}; \
			echo test $${i} done; \
		done ; \
		mv $(TESTS_LOGS) code; \
		cd "code"; \
		cat $(TESTS_LOGS) > all_tests_results.txt; \
		X=$$(grep "^r(" all_tests_results.txt); echo -n "$$X"; [ $$(echo $$X | wc -w) -eq 0 ]  ;
    

code/ado/synth_runner.html: code/ado/synth_runner.smcl
	$(STATABATCH) do code/gen_html_help.do

paper: writeups/synth_runner_sj.pdf

#The lyx --exports often return error 127 (on Windows) but still produce the file fine
writeups/synth_runner_sj.pdf: writeups/synth_runner_sj.lyx
	cd writeups && lyx --export pdf2 synth_runner_sj.lyx

writeups/synth_runner_sj.tex: writeups/synth_runner_sj.lyx
	cd writeups && lyx --export pdflatex synth_runner_sj.lyx

check_paper: writeups/synth_runner_sj.tex
	chktex -n1 -n3 -n15 -n17 -n9 -n36 writeups/synth_runner_sj.tex

