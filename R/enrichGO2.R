##' Given a vector of gene identifiers, this function returns GO term enrichment
##' results based on a hypergeometric test with duplication support in the test 
##' set.
##' 
##' @title GO Term Enrichment with Hypergeometric Test
##' @param gene a vector of gene SYMBOL ids (here the test set)
##' @param OrgDb OrgDb
##' @param keytype Gene ID type of test set
##' @param ont One of "MF", "BP", "CC" or "ALL"
##' @param pvalueCutoff pvalue cutoff
##' @param pAdjustMethod one of "holm", "hochberg", "hommel", 
##' "bonferroni", "BH", "BY", "fdr", "none"
##' @param universe background genes
##' @param qvalueCutoff qvalue cutoff
##' @param minGSSize minimum size of each gene set in annotation system
##' @param maxGSSize maximum size of each gene set in annotation system
##' @param pool If ont='ALL', whether 3 GO ontologies should be combined
##' @return A \code{feaResult} instance.
##' @seealso \code{\link{feaResult-class}}
##' @examples 
##' # The method supports duplicated elements in 'gene', 
##' # which should be gene SYMBOL ids for GO term enrichment.
##' gene <- c(rep("HDAC1",4), rep("HDAC3",2), "SOX8", "KLK14")
##' # data(targetList)
##' # ego <- enrichGO2(gene = gene, OrgDb="org.Hs.eg.db", ont="MF",
##' #                  universe=names(targetList))
##' @export
enrichGO2 <- function(gene,
                     OrgDb,
                     keytype = "SYMBOL",
                     ont="MF",
                     pvalueCutoff=0.05,
                     pAdjustMethod="BH",
                     universe,
                     qvalueCutoff = 0.2,
                     minGSSize = 5,
                     maxGSSize = 500,
                     pool=FALSE) {
  
  ont %<>% toupper
  ont <- match.arg(ont, c("BP", "CC", "MF", "ALL"))
  # GO_DATA <- clusterProfiler:::get_GO_data(OrgDb, ont, keytype)
  # download GO_DATA.rds from AnnotationHub to save time by avoiding 
  # builing GO_DATA from scratch
  eh <- suppressMessages(ExperimentHub())
  GO_DATA <- suppressMessages(eh[["EH3231"]])
  if (missing(universe))
    universe <- NULL
  
  res <- enricher_internal(gene,
                           pvalueCutoff=pvalueCutoff,
                           pAdjustMethod=pAdjustMethod,
                           universe = universe,
                           qvalueCutoff = qvalueCutoff,
                           minGSSize = minGSSize,
                           maxGSSize = maxGSSize,
                           USER_DATA = GO_DATA)
    
  if (is.null(res))
    return(res)
  res <- select_ont(res, ont, GO_DATA)
  og(res) <- get_organism(OrgDb)
  ont(res) <- ont
  return(res)
}
