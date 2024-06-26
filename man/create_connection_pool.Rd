% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/connection.R
\name{create_connection_pool}
\alias{create_connection_pool}
\title{Create a pool of database connections}
\usage{
create_connection_pool(drv = "duckdb::duckdb()", dbdir = ":memory:", ...)
}
\arguments{
\item{drv}{DB driver (default is duckdb::duckdb())}

\item{...}{additional params to pass to pool::dbPool()}

\item{dbpath}{path to database}

\item{with_login}{(default = FALSE) flag to check R environment variables
for login info and/or prompt for password}
}
\value{
pool of connection objects
}
\description{
Generate a pool object from which connection objects can be
checked out.
}
\keyword{internal}
