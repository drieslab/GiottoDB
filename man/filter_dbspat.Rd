% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dbSpatProxy.R
\name{filter_dbspat}
\alias{filter_dbspat}
\title{Filter dbSpatProxyData}
\usage{
\S4method{filter_dbspat}{dbPolygonProxy,function,missing}(x, by_geom = NULL, by_value = NULL, ...)
}
\arguments{
\item{x}{dbSpatProxyData}

\item{by_geom, by_value}{dplyr/dbplyr function to manipulate the data with
across either the geometry OR value data.}
}
\description{
Internal function to abstract away the differences in handling of filtering
data for dbPolygonProxy and dbPointsProxy. This is because the geometry and
values (attributes) are separated into two tables for dbPolygonProxy but are
present in a single table for dbPointsProxy. This function accepts
\code{dbSpatProxyData} as input, but the function passed to by_geom or by_value
should be defined for the internal \code{tbl_sql}.
}
\examples{
# This is an internal, so example should not be run
\dontrun{
dbpoly <- sim_dbPolygonProxy()
dbpoly_filtered <- filter_dbspat(
  x = dbpoly,
  by_value = function(dbspd) {
    dplyr::filter(dbspd, poly_ID == '101161259912191124732236989250178928032')
  }
)
dbpoly_filtered
dbpoly_filtered <- filter_dbspat(
  x = dbpoly,
  by_geom = function(dbspd) {
    dbspd \%>\% dplyr::filter(x > 6500)
  }
)
dbpoly_filtered
}
}
\keyword{internal}
