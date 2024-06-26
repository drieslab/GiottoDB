% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{getBackendID}
\alias{getBackendID}
\title{Get the backend hash ID from the database path}
\usage{
getBackendID(path = ":temp:", extension = ".duckdb")
}
\arguments{
\item{path}{directory path to the database. Accepts :memory: and :temp:
inputs as well}

\item{extension}{file extension of database backend (default = '.duckdb')}
}
\description{
Get the backend hash ID from the database path
}
