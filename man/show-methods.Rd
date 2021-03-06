% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/feaResult-methods.R, R/gessResult-methods.R,
%   R/qSig-methods.R
\docType{methods}
\name{show}
\alias{show}
\alias{show,feaResult-method}
\alias{show,gessResult-method}
\alias{show,qSig-method}
\title{show method}
\usage{
\S4method{show}{feaResult}(object)

show(object)

\S4method{show}{qSig}(object)
}
\arguments{
\item{object}{object used for show}
}
\value{
message
}
\description{
show \code{\link{qSig}}, \code{\link{gessResult}}, \code{\link{feaResult}}
objects
}
\examples{
fr <- feaResult(result=dplyr::tibble(id=letters[seq_len(10)], 
                                     val=seq_len(10)),
                organism="human", ontology="MF", drugs=c("d1", "d2"), 
                targets=c("t1","t2"))
fr 
gr <- gessResult(result=dplyr::tibble(pert=letters[seq_len(10)], 
                               val=seq_len(10)), 
                 query=list(up=c("g1","g2"), down=c("g3","g4")),
                 gess_method="LINCS", refdb="path/to/lincs/db")
gr
}
