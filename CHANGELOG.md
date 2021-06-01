# Change Log
All notable changes to this project will be documented in this file per [Keep a Changelog](http://keepachangelog.com).
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
### Added
 - When synth errors on a treatment unit, change to redoing the analysis uncaptured so that output/errors are visible to help debugging. Add an option `noredo_tr_error` to not do this. 
 - Option to save all the variable and unit weights by specifying both `aggfile_v` and `aggfile_w'.
### Fixed
 - made `trlinediff` work with all the graphs.
 - Fixed `single_treatment_graphs` to work when `mod(n units, 10)==0`
 - Fixed formatting of help.
 - Renamed `calc_RMSPE.ado` to `calc_rmspe.ado` because when `net install`ing on Linux all files are made lower-case!
 - Fixed normalization/scale bug in `calc_rsmpe.ado` (relative comparisons were correct). 

## [1.6.0]
### Added
 - Help files for the graphing commands
### Changed
 - Removed some redundant options in the graphing commands

## [1.5.0]
### Added
 - The `gen_var` to easily include the synthetic control estimates in the dataset.
### Changed
 - Deprecated `keep(file)` and `replace` options (in favor `gen_var`)

## [1.4.0]
### Added
 - Added dynamic setting of synth's xperiod and mspeperiod option.

### Changed
 - With multiple treatment periods, restrict history the maximim common support. Added option to maintain old behavior (allowing maximal histories in estimation).
 - Relabel the row labels the return matrix to be more intuitive (pre vs post numbers).

## [1.3.0]
### Added
 - Added dynamic covariates, dynamic donor pool, determinism, parallel support, and more unit tests.

## [1.2.0]
### Added
 - A separate testing suite aside from usage.do.

### Fixed
 - Allowed for gaps in the time variable. The panel should still be strongly balanced with no missing values the units.

### Changed
 - Removed "pseudo t-statistic" nomenclature in favor of "standardized effect". This affected some return value names.
 - Update docs.

## [1.1.6]
### Fixed
 - Recover more gracefully from errors when estimating treatment effects.

## [1.1.5]
### Fixed
 - Recover gracefully (and report on) optimization errors by donors.
 - Recover (and say why) from a too low max_lead.
 - Update docs.
 - Allow checking version programmatically.

## [1.1.4] - 2016-05-02
### Fixed
 - Issue with multiple treatment units/per_rmspe_mult
 - Cleanup better after run

### Changed
 - Update docs and source code notes.

## [1.1.4] - 2016-04-18
### Fixed
 - Allow non-consecutive IDs in graphing

## [1.1.3] - 2016-04-02
### Fixed
 - allow keep files without file extensions 
 - make graphs look better on older Stata's

### Changed
 - Fixed typos in documentation

## [1.1.2] - 2016-03-31
### Changed
 - Fixed typos in documentation
 
## [1.1.1] - 2016-03-02
### Fixed
 - Allow new additions to work on Stata v12 and v13.

## [1.1.0] - 2016-03-01
### Added
 - Only use lots of memory when computing CI. By default if # of placebo averages is very large, do a random sample.

### Changed
 - Update docs


