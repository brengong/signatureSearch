GSEA_fgsea2 <- function(geneList,
                        exponent,
                        nPerm,
                        minGSSize,
                        maxGSSize,
                        pvalueCutoff,
                        pAdjustMethod,
                        verbose,
                        nproc=1,
                        USER_DATA) {
  
  if(verbose)
    message("preparing geneSet collections...")
  
  geneSets <- get("PATHID2EXTID", envir = USER_DATA)
  
  if(verbose)
    message("excluding gene sets that have no intersect with drug targets")
  
  logic <- vapply(geneSets, function(x) 
    ifelse(length(intersect(x, names(geneList)[geneList!=0]))==0, FALSE, TRUE),
    FUN.VALUE = logical(1))
  geneSets <- geneSets[logic]
  geneSets <- lapply(geneSets, function(x) intersect(x, names(geneList)))
  if(verbose)
    message("Excluding gene sets that beyond size limitation")
  logic <- vapply(geneSets, function(x) 
    length(x)<=maxGSSize & length(x)>=minGSSize, FUN.VALUE = logical(1))
  geneSets <- geneSets[logic]
  
  if(verbose)
    message("GSEA analysis...")
  
  tmp_res <- fgsea2(pathways=geneSets,
                    stats=geneList,
                    nperm=nPerm,
                    minSize=minGSSize,
                    maxSize=maxGSSize,
                    gseaParam=exponent,
                    nproc = nproc)
  
  p.adj <- p.adjust(tmp_res$pval, method=pAdjustMethod)
  qvalues <- calculate_qvalue(tmp_res$pval)
  
  Description <- TERM2NAME(tmp_res$pathway, USER_DATA)
  
  ledge <- vapply(tmp_res$leadingEdge, paste0, collapse='/', 
                  FUN.VALUE = character(1))
  ledge_rank <- vapply(tmp_res$ledge_rank, paste0, collapse='/', 
                       FUN.VALUE = character(1))
  if(verbose)
      message("ledge_rank included")
  res <- data.frame(
    ID = as.character(tmp_res$pathway),
    Description = Description,
    setSize = tmp_res$size,
    enrichmentScore = tmp_res$ES,
    NES = tmp_res$NES,
    pvalue = tmp_res$pval,
    p.adjust = p.adj,
    qvalues = qvalues,
    leadingEdge = ledge,
    ledge_rank = ledge_rank,
    stringsAsFactors = FALSE
  )
  
  res <- res[!is.na(res$pvalue),]
  res <- res[ res$pvalue <= pvalueCutoff, ]
  res <- res[ res$p.adjust <= pvalueCutoff, ]
  idx <- order(res$enrichmentScore, decreasing = TRUE)
  res <- res[idx, ]
  
  if (nrow(res) == 0) {
    message("No term enriched under specific pvalueCutoff...")
    return(NULL)
  }
  
  row.names(res) <- res$ID
  
  if (verbose)
    message("done...")
  
  feaResult(
      result    = as_tibble(res),
      targets   = geneList)
}

## Generic function for gene set enrichment analysis.
## GSEA method is modified to accept geneList with large portion of zeros
GSEA_internal2 <- function(geneList,
                            exponent,
                            nPerm,
                            minGSSize,
                            maxGSSize,
                            pvalueCutoff,
                            pAdjustMethod,
                            verbose,
                            USER_DATA,
                            nproc=1) {
  if (is.unsorted(-geneList))
    stop("geneList should be a decreasing sorted vector...")
  res <- GSEA_fgsea2(geneList          = geneList,
                     exponent          = exponent,
                     nproc             = nproc,
                     nPerm             = nPerm,
                     minGSSize         = minGSSize,
                     maxGSSize         = maxGSSize,
                     pvalueCutoff      = pvalueCutoff,
                     pAdjustMethod     = pAdjustMethod,
                     verbose           = verbose,
                     USER_DATA         = USER_DATA)
  if(is.null(res))
    return(NULL)
  return(res)
}