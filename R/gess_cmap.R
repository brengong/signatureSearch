#' @title CMAP Search Method
#' 
#' @description 
#' Implements the original Gene Expression Signature Search (GESS) from 
#' Lamb et al (2006) known as Connectivity Map (CMap). The method uses as query 
#' the two label sets of the most up- and down-regulated genes from a 
#' genome-wide expression experiment, while the reference database is composed 
#' of rank transformed expression profiles (e.g. ranks of LFC or z-scores).
#' @details 
#' Lamb et al. (2006) introduced the gene expression-based search method known 
#' as Connectivity Map (CMap) where a GES database is searched with a query GES 
#' for similar entries. Specifically, this GESS method uses as query the two 
#' label sets of the most up- and down-regulated genes from a genome-wide 
#' expression experiment, while the reference database is composed of rank 
#' transformed expression profiles (e.g.ranks of LFC or z-scores). The actual 
#' GESS algorithm is based on a vectorized rank difference calculation. The 
#' resulting Connectivity Score expresses to what degree the query up/down gene 
#' sets are enriched on the top and bottom of the database entries, 
#' respectively. The search results are a list of perturbagens such as drugs 
#' that induce similar or opposing GESs as the query. Similar GESs suggest 
#' similar physiological effects of the corresponding perturbagens. 
#' Although several variants of the CMAP algorithm are available in other 
#' software packages including Bioconductor, the implementation provided by
#' \code{signatureSearch} follows the original description of the authors as 
#' closely as possible. 
#' 
#' @section Column description:
#' Descriptions of the columns specific to the CMAP method are given below. 
#' Note, the additional columns, those that are common among the GESS methods, 
#' are described in the help file of the \code{gessResult} object.
#' \itemize{
#'     \item raw_score: bi-directional enrichment score (Kolmogorov-Smirnov 
#'     statistic) of up and down set in the query siganture
#'     \item scaled_score: raw_score scaled to valules from 1 to -1 by 
#'     dividing the positive and negative scores with the maxmum positive score 
#'     and the absolute value of the minimum negative score, respectively.
#' }
#' 
#' @param qSig \code{\link{qSig}} object defining the query signature including
#' the GESS method (should be 'CMAP') and the path to the reference database.
#' For details see help of \code{qSig} and \code{qSig-class}.
#' @param chunk_size number of database entries to process per iteration to 
#' limit memory usage of search.
#' @param ref_trts character vector. If users want to search against a subset 
#' of the reference database, they could set ref_trts as a character vector 
#' representing column names (treatments) of the subsetted refdb. 
#' @param workers integer(1) number of workers for searching the reference
#' database parallelly, default is 1.
#' @return \code{\link{gessResult}} object, the result table contains the 
#' search results for each perturbagen in the reference database ranked by 
#' their signature similarity to the query.
#' @import methods
#' @seealso \code{\link{qSig}}, \code{\link{gessResult}}, \code{\link{gess}}
#' @references For detailed description of the CMap method, please refer to: 
#' Lamb, J., Crawford, E. D., Peck, D., Modell, J. W., Blat, I. C., 
#' Wrobel, M. J., Golub, T. R. (2006). The Connectivity Map: 
#' using gene-expression signatures to connect small molecules, genes, and 
#' disease. Science, 313 (5795), 1929-1935. 
#' URL: https://doi.org/10.1126/science.1132939
#' @examples 
#' db_path <- system.file("extdata", "sample_db.h5", 
#'                        package = "signatureSearch")
#' # qsig_cmap <- qSig(query = list(
#' #                   upset=c("230", "5357", "2015", "2542", "1759"),
#' #                   downset=c("22864", "9338", "54793", "10384", "27000")),
#' #                   gess_method = "CMAP", refdb = db_path)
#' # cmap <- gess_cmap(qSig=qsig_cmap, chunk_size=5000)
#' # result(cmap)
#' @export
gess_cmap <- function(qSig, chunk_size=5000, ref_trts=NULL, workers=1){
    if(!is(qSig, "qSig")) stop("The 'qSig' should be an object of 'qSig' class")
    # stopifnot(validObject(qSig))
    if(gm(qSig) != "CMAP"){
        stop(paste("The 'gess_method' slot of 'qSig' should be 'CMAP'",
                   "if using 'gess_cmap' function!"))
    }
    db_path <- determine_refdb(refdb(qSig))
    qsig_up <- qr(qSig)$upset
    qsig_dn <- qr(qSig)$downset
    res <- cmapEnrich(db_path, upset=qsig_up, downset=qsig_dn, 
                      chunk_size=chunk_size, ref_trts=ref_trts, workers=workers)
    res <- sep_pcf(res)
    # add target column
    target <- suppressMessages(get_targets(res$pert))
    res <- left_join(res, target, by=c("pert"="drug_name"))
    
    x <- gessResult(result = as_tibble(res),
                    query = qr(qSig),
                    gess_method = gm(qSig),
                    refdb = refdb(qSig))
    return(x)
}

#' @importFrom data.table frank
rankMatrix <- function(x, decreasing=TRUE) {
  if(!is(x, "matrix") | !is.numeric(x)) stop("x needs to be numeric matrix!")
  if(is.null(rownames(x)) | is.null(colnames(x))) 
    stop("matrix x lacks colnames and/or rownames!")
  if(decreasing) { mysign <- -1 } else { mysign <- 1 }
  rankma <- vapply(seq(ncol(x)), function(z) data.table::frank(mysign * x[,z]))
  rownames(rankma) <- rownames(x); colnames(rankma) <- colnames(x)
  return(rankma)
}

#' @importFrom DelayedArray colAutoGrid
#' @importFrom DelayedArray read_block
cmapEnrich <- function(db_path, upset, downset, 
                       chunk_size=5000, ref_trts=NULL, workers=4) {
  ## calculate raw.score of query to blocks (e.g., 5000 columns) of full refdb
  full_mat <- HDF5Array(db_path, "assay")
  rownames(full_mat) <- as.character(HDF5Array(db_path, "rownames"))
  colnames(full_mat) <- as.character(HDF5Array(db_path, "colnames"))
  
  if(! is.null(ref_trts)){
      trts_valid <- trts_check(ref_trts, colnames(full_mat))
      full_mat <- full_mat[, trts_valid]
  }
  
  full_dim <- dim(full_mat)
  full_grid <- colAutoGrid(full_mat, ncol=min(chunk_size, ncol(full_mat)))
  ### The blocks in 'full_grid' are made of full columns 
  nblock <- length(full_grid) 
  
  raw.score <- unlist(bplapply(seq_len(nblock), function(b){
    ref_block <- read_block(full_mat, full_grid[[b]])
    mat <- ref_block
    rankLup <- lapply(colnames(mat), function(x) sort(rank(-1*mat[,x])[upset]))
    rankLdown <- lapply(colnames(mat), 
                         function(x) sort(rank(-1*mat[,x])[downset]))
    ## Compute raw and scaled connectivity scores
    raw.score <- vapply(seq_along(rankLup), function(x) 
        .s(rankLup[[x]], rankLdown[[x]], n=nrow(mat)),
        FUN.VALUE=numeric(1))
    }, BPPARAM = MulticoreParam(workers = workers)))
  
  # ## Read in matrix in h5 file by chunks
  # mat_dim <- getH5dim(db_path)
  # mat_nrow <- mat_dim[1]
  # mat_ncol <- mat_dim[2]
  # ceil <- ceiling(mat_ncol/chunk_size)
  # ## get ranks of up and down genes in DB
  # rankLup <- NULL
  # rankLdown <- NULL
  # for(i in seq_len(ceil)){
  #   mat <- readHDF5mat(db_path,
  #                   colindex=(chunk_size*(i-1)+1):min(chunk_size*i, mat_ncol))
  #   rankLup1 <- lapply(colnames(mat), function(x) sort(rank(-1*mat[,x])[upset]))
  #   rankLdown1 <- lapply(colnames(mat), 
  #                        function(x) sort(rank(-1*mat[,x])[downset]))
  #   rankLup <- c(rankLup, rankLup1)
  #   rankLdown <- c(rankLdown, rankLdown1)
  # }
  # 
  # ## Compute raw and scaled connectivity scores
  # raw.score <- vapply(seq_along(rankLup), function(x) 
  #                              .s(rankLup[[x]], rankLdown[[x]], n=mat_nrow),
  #                     FUN.VALUE=numeric(1))
  
  score <- .S(raw.score)
  
  ## Assemble results
  resultDF <- data.frame(set = colnames(full_mat), 
                         trend = ifelse(score >=0, "up", "down"),
                         raw_score = raw.score,
                         scaled_score = score,
                         N_upset = length(upset),
                         N_downset = length(downset), stringsAsFactors = FALSE)
  resultDF <- resultDF[order(abs(resultDF$scaled_score), decreasing=TRUE), ]
  rownames(resultDF) <- NULL
  return(resultDF)
}

## Fct to compute a and b
.ks <- function( V, n ) {
    t <- length( V )
    if( t == 0 )  {
        return( 0 )
    } else {
        if (is.unsorted(V)) V <- sort(V)
        d <- seq_len(t) / t - V / n
        a <- max( d )
        b <- -min( d ) + 1 / t
        ifelse( a > b, a, -b )
    }
}

# .ks <- function(V, n) {
#   t <- length(V)
#   a <- max(seq_len(t) / t - V / n)
#   b <- max(V / n - (seq_len(t)-1)/t)
#   ifelse(a > b, a, -b)
# }

## Fct to compute ks_up and ks_down
.s <- function(V_up, V_down, n) {
  ks_up <- .ks(V_up, n)
  ks_down <- .ks(V_down, n)
  ifelse(sign(ks_up) == sign(ks_down), 0, ks_up - ks_down)
}

## Fct to scale scores
.S <- function(scores) {
  p <- max(scores)
  q <- min(scores)
  ifelse(scores == 0, 0, ifelse(scores > 0, scores / p, -scores / q))
}
