% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/io.R
\docType{class}
\name{GCT object}
\alias{GCT object}
\title{An S4 Class to Represent a GCT Object}
\description{
The GCT class serves to represent annotated
  matrices. The \code{mat} slot contains the numeric matrix data and the
  \code{rdesc} and \code{cdesc} slots contain data frames with
  annotations about the rows and columns, respectively
}
\section{Slots}{

\describe{
\item{\code{mat}}{a numeric matrix}

\item{\code{rid}}{a character vector of row ids}

\item{\code{cid}}{a character vector of column ids}

\item{\code{rdesc}}{a \code{data.frame} of row descriptors}

\item{\code{rdesc}}{a \code{data.frame} of column descriptors}

\item{\code{src}}{a character indicating the source (usually file path) 
of the data}
}}

\seealso{
\code{\link{parse_gctx}}
}
