
# theft <img src="man/figures/logo.png" align="right" width="120" />

[![CRAN
version](http://www.r-pkg.org/badges/version/catch22)](http://www.r-pkg.org/pkg/theft)
[![CRAN RStudio mirror
downloads](http://cranlogs.r-pkg.org/badges/catch22)](http://www.r-pkg.org/pkg/theft)
[![DOI](https://zenodo.org/badge/351259952.svg)](https://zenodo.org/badge/latestdoi/351259952)

Tools for Handling Exploratory Features from Time-series (theft)

## Installation

*Coming to CRAN soon… Stay posted\!*

You can install the development version of `theft` from GitHub using the
following:

``` r
devtools::install_github("hendersontrent/theft")
```

## General purpose

`theft` is a software package for R that facilitates user-friendly
access to a structured analytical pipeline for the computation,
analysis, and visualisation of time-series features. The package pulls
and concatenates a large number of time-series feature statistic methods
from a range of existing R packages and lets the user specify which
groups (or all) of the these features to calculate. The packages which
`theft` currently pulls together include:

  - [catch22](https://github.com/hendersontrent/catch22)
  - [feasts](https://feasts.tidyverts.org)
  - [tsfeatures](https://github.com/robjhyndman/tsfeatures)

The package also contains a suite of tools for automatic normalisation
of extracted feature vectors, dimension reduction, and data
visualisation. The entire package is developed around principles of
[tidy
data](https://cran.r-project.org/web/packages/tidyr/vignettes/tidy-data.html),
meaning it integrates with and uses existing
[tidyverse](https://www.tidyverse.org) and
[tidyverts](https://tidyverts.org) software.

## Citation

``` 

To cite package 'theft' in publications use:

  Trent Henderson (2021). theft: Tools for Handling Exploratory
  Features from Time-series. R package version 0.1.2.

A BibTeX entry for LaTeX users is

  @Manual{,
    title = {theft: Tools for Handling Exploratory Features from Time-series},
    author = {Trent Henderson},
    year = {2021},
    note = {R package version 0.1.2},
  }
```
