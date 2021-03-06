##' MeanAbs enrichment analysis with GO terms.
##'
##' @title MeanAbs Enrichment Analysis for GO
##' @param geneList named numeric vector with gene SYMBOLs in the name slot 
##' decreasingly ranked by scores in the data slot.
##' @param ont one of "BP", "MF", "CC" or "ALL"
##' @param OrgDb OrgDb
##' @param keyType keytype of gene
##' @param nPerm permutation numbers
##' @param minGSSize integer, minimum size of each gene set in annotation system
##' @param maxGSSize integer, maximum size of each gene set in annotation system
##' @param pvalueCutoff pvalue cutoff
##' @param pAdjustMethod pvalue adjustment method
##' @return \code{\link{feaResult}} object
##' @author Yuzhu Duan
##' @examples 
##' data(targetList)
##' #mg <- mabsGO(geneList=targetList, ont="MF", OrgDb="org.Hs.eg.db",
##' #             pvalueCutoff=1)
##' #head(mg)
##' @export
mabsGO <- function(geneList,
                  ont           = "BP",
                  OrgDb,
                  keyType       = "SYMBOL",
                  nPerm         = 1000,
                  minGSSize     = 5,
                  maxGSSize     = 500,
                  pvalueCutoff  = 0.05,
                  pAdjustMethod = "BH") {

    ont %<>% toupper
    ont <- match.arg(ont, c("BP", "CC", "MF", "ALL"))

    #GO_DATA <- get_GO_data(OrgDb, ont, keytype="SYMBOL")
    # download GO_DATA.rds from AnnotationHub to save time by avoiding 
    # builing GO_DATA from scratch
    eh <- suppressMessages(ExperimentHub())
    GO_DATA <- suppressMessages(eh[["EH3231"]])
    
    res <-  mabs_internal(geneList = geneList,
                          nPerm = nPerm,
                          minGSSize = minGSSize,
                          maxGSSize = maxGSSize,
                          pvalueCutoff = pvalueCutoff,
                          pAdjustMethod = pAdjustMethod,
                          USER_DATA = GO_DATA)

    if (is.null(res))
        return(res)
    res <- select_ont(res, ont, GO_DATA)
    og(res) <- get_organism(OrgDb)
    ont(res) <- ont
    return(res)
}

##' MeanAbs enrichment analysis with KEGG pathways.
##'
##' @title MeanAbs Enrichment Analysis for KEGG
##' @param geneList named numeric vector with gene/target ids in the name slot 
##' decreasingly ranked by scores in the data slot.
##' @param organism supported organism listed in 
##' URL: http://www.genome.jp/kegg/catalog/org_list.html
##' @param keyType one of 'kegg', 'ncbi-geneid', 'ncib-proteinid' and 'uniprot'
##' @param nPerm permutation numbers
##' @param minGSSize integer, minimum size of each gene set in annotation system
##' @param maxGSSize integer, maximum size of each gene set in annotation system
##' @param pvalueCutoff pvalue cutoff
##' @param pAdjustMethod pvalue adjustment method
##' @return \code{\link{feaResult}} object
##' @examples 
##' # Gene Entrez id should be used for KEGG enrichment
##' data(geneList, package="DOSE")
##' #geneList[100:length(geneList)]=0
##' #mk <- mabsKEGG(geneList=geneList, pvalueCutoff = 1)
##' #head(mk)
##' @export
mabsKEGG <- function(geneList,
                    organism          = 'hsa',
                    keyType           = 'kegg',
                    nPerm             = 1000,
                    minGSSize         = 5,
                    maxGSSize         = 500,
                    pvalueCutoff      = 0.05,
                    pAdjustMethod     = "BH") {

    species <- organismMapper(organism)
    KEGG_DATA <- prepare_KEGG(species, "KEGG", keyType)

    res <-  mabs_internal(geneList = geneList,
                          nPerm = nPerm,
                          minGSSize = minGSSize,
                          maxGSSize = maxGSSize,
                          pvalueCutoff = pvalueCutoff,
                          pAdjustMethod = pAdjustMethod,
                          USER_DATA = KEGG_DATA)

    if (is.null(res))
        return(res)

    og(res) <- species
    ont(res) <- "KEGG"
    return(res)
}

