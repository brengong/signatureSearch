% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/gess_res_summary.R
\name{sim_score_grp}
\alias{sim_score_grp}
\title{Summary Scores by Groups of Cell Types}
\usage{
sim_score_grp(tib, grp1, grp2, score_column)
}
\arguments{
\item{tib}{tibble in gessResult object}

\item{grp1}{character vector, group 1 of cell types, e.g., tumor cell types}

\item{grp2}{character vector, group 2 of cell types, e.g., normal cell types}

\item{score_column}{character, column name of similarity scores to be 
grouped}
}
\value{
tibble
}
\description{
Function appends two columns (score_column_grp1, score_column_grp2) to GESS 
result tibble. The appended columns contain summary scores for groups of 
cell types, such as normal and tumor cells.
}
\examples{
gr <- gessResult(result=dplyr::tibble(pert=c("p1", "p1", "p2", "p3"),
                                      cell=c("MCF7", "SKB", "MCF7", "SKB"),
                                      type=rep("trt_cp", 4),
                                      NCS=c(1.2, 1, 0.9, 0.6)),
                 query=list(up="a", down="b"), 
                 gess_method="LINCS", refdb="path/to/refdb")
df <- sim_score_grp(result(gr), grp1="SKB", grp2="MCF7", "NCS")
}
