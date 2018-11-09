% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/gess_fisher.R
\name{gess_fisher}
\alias{gess_fisher}
\title{gess_fisher}
\usage{
gess_fisher(qSig, higher, lower, chunk_size = 5000)
}
\arguments{
\item{qSig}{`qSig` object, The 'gess_method' slot of 'qSig' should be 'Fisher'}

\item{higher}{The 'higher' threshold. If not 'NULL', genes with a score larger than 'higher' will be included in the gene set with sign +1. 
At least one of 'lower' and 'higher' must be specified.}

\item{lower}{The lower threshold. If not 'NULL', genes with a score smaller than 'lower' will be included in the gene set with sign -1. 
At least one of 'lower' and 'higher' must be specified.}

\item{chunk_size}{size of chunk per processing}
}
\value{
gessResult object represents a list of drugs in reference database ranked by their similarity to query signature
}
\description{
Fisher method for GESS
}