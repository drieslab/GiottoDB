
# GiottoDB  <img src="man/figures/logo.png" align="right" alt="" width="160" />
<!-- badges: start -->
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL%203.0-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN status](https://www.r-pkg.org/badges/version/GiottoDB)](https://CRAN.R-project.org/package=GiottoDB)
[![Bioconductor: not published](https://img.shields.io/badge/Bioconductor-not%20published-red.svg)](https://bioconductor.org/)
<!-- badges: end -->

The goal of `GiottoDB` is to enable database functionality for [Giotto objects](https://drieslab.github.io/Giotto_website/) through [dbverse](https://github.com/drieslab/dbverse). 

## Installation

``` r
# install.packages("pak")
pak::pak("drieslab/GiottoDB")
```

## GiottoDB Functionality
- [x] [GiottoClass::createExprObj()](https://drieslab.github.io/GiottoClass/reference/createExprObj.html)
- [ ] [GiottoClass::createGiottoPoints()](https://drieslab.github.io/GiottoClass/reference/createGiottoPoints.html)
- [ ] [GiottoClass::createGiottoPolygon()](https://drieslab.github.io/GiottoClass/reference/createGiottoPolygon.html)
- [x] [GiottoClass::calculateOverlap()](https://drieslab.github.io/GiottoClass/reference/calculateOverlap.html)
- [x] [GiottoClass::overlapToMatrix()](https://drieslab.github.io/GiottoClass/reference/overlapToMatrix.html)
- [x] [Giotto::filterGiotto()](https://drieslab.github.io/Giotto_website/reference/filterGiotto.html)
- [x] [Giotto::normalizeGiotto()](https://drieslab.github.io/Giotto_website/reference/normalizeGiotto.html)
- [ ] [Giotto::calculateHVF()](https://drieslab.github.io/Giotto_website/reference/calculateHVF.html)
- ...
