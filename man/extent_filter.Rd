% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dbSpatProxy.R
\name{extent_filter}
\alias{extent_filter}
\alias{extent_filter,dbPointsProxy,SpatExtent,logical-method}
\alias{extent_filter,ANY,SpatExtent,missing-method}
\alias{extent_filter,ANY,SpatExtent,logical-method}
\title{Filter by terra SpatExtent}
\usage{
\S4method{extent_filter}{dbPolygonProxy,SpatExtent,logical}(x, extent, include, method = c("all", "mean"), ...)

\S4method{extent_filter}{dbPointsProxy,SpatExtent,logical}(x, extent, include, ...)

\S4method{extent_filter}{ANY,SpatExtent,missing}(x, extent, include, ...)

\S4method{extent_filter}{ANY,SpatExtent,logical}(x, extent, include, ...)
}
\arguments{
\item{x}{dbSpatProxyData}

\item{extent}{SpatExtent defining a spatial region to select}

\item{include}{logical vector of the form c(bottom, left, top, right) which
determines whether the specified extent bound should be inclusive of the bound
value itself. (ie greater/less than OR equal to (default) vs only greater/less than)}

\item{method}{character. Method of selection. 'mean' (default) selects a polygon
if the mean point of all vertex coordinates falls within the \code{extent}.
'all' selects a polygon if ANY of its vertices fall within the \code{extent}.}

\item{...}{additional params to pass}
}
\description{
Filter database-backed spatial data for only those records that fall within a
spatial \code{extent} as given by a terra \code{SpatExtent} object. This
selection
}
\seealso{
Other Extent processing functions: 
\code{\link{extent_calculate}()}
}
\concept{Extent processing functions}
\keyword{internal}
