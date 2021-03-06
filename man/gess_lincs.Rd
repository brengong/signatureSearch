% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/gess_lincs.R
\name{gess_lincs}
\alias{gess_lincs}
\title{LINCS Search Method}
\usage{
gess_lincs(
  qSig,
  tau = FALSE,
  sortby = "NCS",
  chunk_size = 5000,
  ref_trts = NULL,
  workers = 1
)
}
\arguments{
\item{qSig}{\code{\link{qSig}} object defining the query signature including
the GESS method (should be 'LINCS') and the path to the reference database.
For details see help of \code{qSig} and \code{qSig-class}.}

\item{tau}{TRUE or FALSE, whether to compute the tau score. Note, TRUE is 
only meaningful when the full LINCS database is searched, since accurate Tau 
score calculation depends on the usage of the exact same database their 
background values are based on.}

\item{sortby}{sort the GESS result table based on one of the following 
statistics: `WTCS`, `NCS`, `Tau`, `NCSct` or `NA`}

\item{chunk_size}{number of database entries to process per iteration to 
limit memory usage of search.}

\item{ref_trts}{character vector. If users want to search against a subset 
of the reference database, they could set ref_trts as a character vector 
representing column names (treatments) of the subsetted refdb.}

\item{workers}{integer(1) number of workers for searching the reference
database parallelly, default is 1.}
}
\value{
\code{\link{gessResult}} object, the result table contains the 
search results for each perturbagen in the reference database ranked by 
their signature similarity to the query.
}
\description{
Implements the Gene Expression Signature Search (GESS) from 
Subramanian et al, 2017, here referred to as LINCS. The method uses as 
query the two label sets of the most up- and down-regulated genes from a 
genome-wide expression experiment, while the reference database is composed 
of differential gene expression values (e.g. LFC or z-scores). Note, the 
related CMAP method uses here ranks instead.
}
\details{
Subramanian et al. (2017) introduced a more complex GESS algorithm, 
here referred to as LINCS. While related to CMAP, there are several important
differences among the two approaches. First, LINCS weights the query genes 
based on the corresponding differential expression scores of the GESs in the 
reference database (e.g. LFC or z-scores). Thus, the reference database used 
by LINCS needs to store the actual score values rather than their ranks.
Another relevant difference is that the LINCS algorithm uses a bi-directional
weighted Kolmogorov-Smirnov enrichment statistic (ES) as similarity metric.
}
\section{Column description}{

Descriptions of the columns specific to the LINCS method are given below. 
Note, the additional columns, those that are common among the GESS methods, 
are described in the help file of the \code{gessResult} object.
\itemize{
  \item WTCS: Weighted Connectivity Score, a bi-directional Enrichment 
  Score for an up/down query set. If the ES values of an up set and a down 
  set are of different signs, then WTCS is (ESup-ESdown)/2, otherwise, 
  it is 0. WTCS values range from -1 to 1. They are positive or negative 
  for signatures that are positively or inversely related, respectively, 
  and close to zero for signatures that are unrelated.
  \item WTCS_Pval: Nominal p-value of WTCS computed by comparing WTCS 
  against a null distribution of WTCS values obtained from a large number
  of random queries (e.g. 1000).
  \item WTCS_FDR: False discovery rate of WTCS_Pval.
  \item NCS: Normalized Connectivity Score. To make connectivity scores 
  comparable across cell types and perturbation types, 
  the scores are normalized. Given a vector of WTCS 
  values w resulting from a query, the values are normalized within each 
  cell line c and perturbagen type t to obtain NCS by dividing the WTCS 
  value with the signed mean of the WTCS values within 
  the subset of the signatures in the reference database corresponding to c 
  and t.
  \item Tau: Enrichment score standardized for a given database. 
  The Tau score compares an observed NCS to a large set of NCS values that 
  have been pre-computed for a specific reference database. The query results
  are scored with Tau as a standardized measure ranging from 100 to -100. 
  A Tau of 90 indicates that only 10% of reference perturbations exhibit 
  stronger connectivity to the query. This way one can make more meaningful 
  comparisons across query results. 
  
  Note, there are NAs in the Tau score column, the reason is that the number 
  of signatures in \emph{Qref} that match the cell line of signature \emph{r}
  (the \code{TauRefSize} column in the GESS result) is less than 500, 
  Tau will be set as NA since it is redeemed as there are not large enough 
  samples for computing meaningful Tau scores.
  
  \item TauRefSize: Size of reference perturbations for computing Tau.
  \item NCSct: NCS summarized across cell types. Given a vector of NCS values
  for perturbagen p, relative to query q, across all cell lines c in which p 
  was profiled, a cell-summarized connectivity score is obtained using a 
  maximum quantile statistic. It compares the 67 and 33 quantiles of 
  NCSp,c and retains whichever is of higher absolute magnitude.
}
}

\examples{
db_path <- system.file("extdata", "sample_db.h5", 
                       package = "signatureSearch")
#qsig_lincs <- qSig(query = list(
#                   upset=c("230", "5357", "2015", "2542", "1759"), 
#                   downset=c("22864", "9338", "54793", "10384", "27000")), 
#                   gess_method = "LINCS", refdb = db_path)
#lincs <- gess_lincs(qsig_lincs, sortby="NCS", tau=FALSE)
#result(lincs)
}
\references{
For detailed description of the LINCS method and scores, 
please refer to: Subramanian, A., Narayan, R., Corsello, S. M., Peck, D. D., 
Natoli, T. E., Lu, X., Golub, T. R. (2017). A Next Generation 
Connectivity Map: L1000 Platform and the First 1,000,000 Profiles. Cell, 
171 (6), 1437-1452.e17. URL: https://doi.org/10.1016/j.cell.2017.10.049
}
\seealso{
\code{\link{qSig}}, \code{\link{gessResult}}, \code{\link{gess}}
}
