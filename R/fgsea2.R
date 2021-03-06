# Calculates GSEA statistics for a given query gene set, 
# adapt to large portion of zeros in 'stats'
calcGseaStat2 <- function(stats, selectedStats, gseaParam=1,
                         returnAllExtremes=FALSE,
                         returnLeadingEdge=FALSE) {
  S <- selectedStats
  r <- stats
  p <- gseaParam
  
  S <- sort(S)
  
  m <- length(S)
  N <- length(r)
  ## edited by YD.
  ## set minimum value in stats as weight for genes in set S that have zero 
  ## scores
  coef <- min(r[r!=0])
  NR <- (sum(abs(r[S])^p) + coef*sum(r[S]==0))
  rAdj <- abs(r[S])^p
  if (NR == 0) {
    # this is equivalent to rAdj being rep(eps, m)
    rCumSum <- 0
  } else {
    rCumSum <- cumsum(rAdj) / NR
  }
  
  
  tops <- rCumSum - (S - seq_along(S)) / (N - m)
  if (NR == 0) {
    # this is equivalent to rAdj being rep(eps, m)
    bottoms <- -1
  } else {
    bottoms <- tops - rAdj / NR
  }
  
  maxP <- max(tops)
  minP <- min(bottoms)
  if(minP == -1){
    geneSetStatistic = -1
  } else {
    geneSetStatistic <- maxP
  }
  
  if (!returnAllExtremes && !returnLeadingEdge) {
    return(geneSetStatistic)
  }
  
  res <- list(res=geneSetStatistic)
  if (returnAllExtremes) {
    res <- c(res, list(tops=tops, bottoms=bottoms))
  }
  if (returnLeadingEdge) {
    leadingEdge <- if(minP==-1) NULL 
      else {
        S[seq_along(S) <= which.max(tops)]
      }
    res <- c(res, list(leadingEdge=leadingEdge))
  }
  res
}



#' @import BiocParallel
#' @importFrom fastmatch fmatch
#' @importFrom data.table data.table
#' @importFrom data.table rbindlist
#' @importFrom data.table :=
#' @importFrom utils globalVariables
 
# Runs preranked gene set enrichment analysis.
fgsea2 <- function(pathways, stats, nperm,
                  minSize=1, maxSize=Inf,
                  nproc=1,
                  gseaParam=1,
                  BPPARAM=NULL) {
# message("Using fgsea2 function to run GSEA, which is adapted to accepting
# 'stats' with large portion of zeros.")
    if (is.null(BPPARAM)) {
        if (nproc != 0) {
            if (.Platform$OS.type == "windows") {
                # windows doesn't support multicore, using snow instead
                BPPARAM <- SnowParam(workers = nproc)
            } else {
                BPPARAM <- MulticoreParam(workers = nproc)
            }
        } else {
            BPPARAM <- bpparam()
        }
    }

    minSize <- max(minSize, 1)
    stats <- sort(stats, decreasing=TRUE)
    stats <- abs(stats) ^ gseaParam
    pathwaysFiltered <- lapply(pathways, function(p) 
      { as.vector(na.omit(fmatch(p, names(stats)))) })
    pathwaysSizes <- vapply(pathwaysFiltered, length, integer(1))

    toKeep <- which(minSize <= pathwaysSizes & pathwaysSizes <= maxSize)
    m <- length(toKeep)

    if (m == 0) {
        return(data.table(pathway=character(),
                          pval=numeric(),
                          padj=numeric(),
                          ES=numeric(),
                          NES=numeric(),
                          nMoreExtreme=numeric(),
                          size=integer(),
                          leadingEdge=list(),
                          ledge_rank=list()))
    }

    pathwaysFiltered <- pathwaysFiltered[toKeep]
    pathwaysSizes <- pathwaysSizes[toKeep]

    K <- max(pathwaysSizes)
    npermActual <- nperm

    gseaStatRes <- do.call(rbind,
                lapply(pathwaysFiltered, calcGseaStat2,
                       stats=stats,
                       returnLeadingEdge=TRUE))


    leadingEdges <- mapply("[", list(names(stats)), 
                           gseaStatRes[, "leadingEdge"], SIMPLIFY = FALSE)
    ledge_rank <- gseaStatRes[, "leadingEdge"]
    pathwayScores <- unlist(gseaStatRes[, "res"])

    granularity <- 1000
    permPerProc <- rep(granularity, floor(npermActual / granularity))
    if (npermActual - sum(permPerProc) > 0) {
        permPerProc <- c(permPerProc, npermActual - sum(permPerProc))
    }

    universe <- seq_along(stats)
    seeds <- sample.int(10^9, length(permPerProc))
    counts <- bplapply(seq_along(permPerProc), function(i) {
        nperm1 <- permPerProc[i]
        leEs <- rep(0, m)
        geEs <- rep(0, m)
        leZero <- rep(0, m)
        geZero <- rep(0, m)
        leZeroSum <- rep(0, m)
        geZeroSum <- rep(0, m)
        if (m == 1) {
            for (i in seq_len(nperm1)) {
                randSample <- sample.int(length(universe), K)
                randEsP <- calcGseaStat2(
                    stats = stats,
                    selectedStats = randSample,
                    gseaParam = 1)
                leEs <- leEs + (randEsP <= pathwayScores)
                geEs <- geEs + (randEsP >= pathwayScores)
                leZero <- leZero + (randEsP <= 0)
                geZero <- geZero + (randEsP >= 0)
                leZeroSum <- leZeroSum + pmin(randEsP, 0)
                geZeroSum <- geZeroSum + pmax(randEsP, 0)
            }
        } else {
            aux <- calcGseaStatCumulativeBatch(
                stats = stats,
                gseaParam = 1,
                pathwayScores = pathwayScores,
                pathwaysSizes = pathwaysSizes,
                iterations = nperm1,
                seed = seeds[i])
            
            leEs = get("leEs", aux)
            geEs = get("geEs", aux)
            leZero = get("leZero", aux)
            geZero = get("geZero", aux)
            leZeroSum = get("leZeroSum", aux)
            geZeroSum = get("geZeroSum", aux)
        }
        data.table(pathway=seq_len(m),
                   leEs=leEs, geEs=geEs,
                   leZero=leZero, geZero=geZero,
                   leZeroSum=leZeroSum, geZeroSum=geZeroSum
                   )
    }, BPPARAM=BPPARAM)

    counts <- rbindlist(counts)

    pvals <- counts[,
      list(pval= sum(geEs) / (sum(geZero) + sum(leZero)),
         # edited by YD. set percent of permutations greater than original 
         # ES as p value
         # since only want to find geneSets enrich at top of 'stats'
         # pval=ifelse(pathwayScores[pathway]>0, sum(geEs) / sum(geZero), 
         # 1 - sum(leEs) / sum(leZero)),
         leZeroMean = sum(leZeroSum) / sum(leZero),
         geZeroMean = sum(geZeroSum) / sum(geZero),
         mean=(abs(sum(leZeroSum))+sum(geZeroSum))/(sum(geZero)+sum(leZero)),
         nLeEs=sum(leEs),
         nGeEs=sum(geEs)
         ),
        by=.(pathway)]
    pvals[, padj := p.adjust(pval, method="BH")]
    pvals[, ES := pathwayScores[pathway]]
    # pvals[, NES := ES / ifelse(ES > 0, geZeroMean, abs(leZeroMean))]
    pvals[, NES := ES / mean]
    pvals[, leZeroMean := NULL]
    pvals[, geZeroMean := NULL]
    pvals[, mean := NULL]

    # pvals[, nMoreExtreme :=  ifelse(ES > 0, nGeEs, nLeEs)]
    # pvals[, nMoreExtreme :=  nGeEs]
    pvals[, nLeEs := NULL]
    pvals[, nGeEs := NULL]

    pvals[, size := pathwaysSizes[pathway]]
    pvals[, pathway := names(pathwaysFiltered)[pathway]]

    pvals[, leadingEdge := .(leadingEdges)]
    pvals[, ledge_rank := .(ledge_rank)]


    # Makes pvals object printable immediatly
    pvals <- pvals[]
    pvals <- pvals[order(pval),]
    pvals
}

# Get rid of check NOTEs
globalVariables(c(".", "leEs", "leZero", "geEs", "geZero", "leZeroSum", 
                  "geZeroSum", "pathway", "padj", "pval", "ES", "NES",
                  "geZeroMean", "leZeroMean", "nMoreExtreme", "nGeEs",
                  "nLeEs", "size", "leadingEdge"), 
                package="signatureSearch")