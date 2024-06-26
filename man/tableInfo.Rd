% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/backend.R
\name{tableInfo}
\alias{tableInfo}
\alias{tableInfo,dbData,missing-method}
\alias{tableInfo,dbPolygonProxy,missing-method}
\title{Get information about the database table}
\usage{
\S4method{tableInfo}{ANY,character}(x, remote_name, ...)

\S4method{tableInfo}{dbData,missing}(x, remote_name, ...)

\S4method{tableInfo}{dbPolygonProxy,missing}(x, remote_name, ...)
}
\arguments{
\item{x}{connector object (hashID of backend, DBI connection, pool), or a
GiottoDB object}

\item{remote_name}{(only needed if x is a connection object) name of table on DB}
}
\value{
a data.table of information about the specified table on the database
}
\description{
Get information about the database table
}
\examples{
dbpoly = sim_dbPolygonProxy()
tableInfo(dbpoly)

dbpoints = sim_dbPointsProxy()
tableInfo(dbpoints)

dbDF = sim_dbDataFrame()
tableInfo(dbDF)
}
