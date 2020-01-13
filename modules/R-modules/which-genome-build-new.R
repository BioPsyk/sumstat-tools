args = commandArgs(trailingOnly=TRUE)

libdir=args[1]
gbin=args[2]
gbout=args[3]
chunksize=args[4]
whichinx=args[5]
SSTOOLS_ROOT=args[6]
# to be added later
path_missing_position_file=NULL
path_multimapped_file=NULL

#/home/people/jesgaa/R/R_from_source/2019-12-17-r-devel/bin/Rscript /home/people/jesgaa/repos/sumstat-tools/modules/R-modules/liftover-stream.R /home/people/jesgaa/R/R_from_source/2019-12-17-r-devel/library "GRCh36" "GRCh38" 100 "chrpos=1,inx=2" /home/people/jesgaa/repos/sumstat-tools

spl <- unlist(strsplit(whichinx, ","))
spl2 <- strsplit(spl, "=")
args <- unlist(lapply(spl2,FUN=function(x){x[1]}))
vals <- as.integer(unlist(lapply(spl2,FUN=function(x){x[2]})))
names(vals) <- args
cix=c(vals[["chrpos"]],vals[["inx"]])

#libdir="/home/people/jesgaa/R/R_from_source/2019-12-17-r-devel/library"
#chr_ix="CHROMOSOME"
#bp_ix="POSITION"
#file="/home/people/jesgaa/data/dbsnp151/tmp/AD_sumstats_Jansenetal.txt.chrpos.sorted"
#gbin="GRCh36"
#gbin="GRCh38"
#chunksize=10000
#SSTOOLS_ROOT="/home/people/jesgaa/repos/sumstat-tools"

.libPaths(libdir)

#load required packages
suppressMessages(library(GenomicRanges))
suppressMessages(library(liftOver))

.coerce_to_GRCh38_from_genome_build_info <- function(gr, gb){
  suppressWarnings(seqlevelsStyle(gr) <- "UCSC")
  if(gb=="GRCh35"){
    ch = import.chain(paste(SSTOOLS_ROOT, "/data/liftover/hg17ToHg38.over.chain", sep=""))
    anngr2.GRCh38 = liftOver(gr, ch)
  }else if(gb=="GRCh36"){
    ch = import.chain(paste(SSTOOLS_ROOT, "/data/liftover/hg18ToHg38.over.chain", sep=""))
    anngr2.GRCh38 = liftOver(gr, ch)
  }else if(gb=="GRCh37"){
    ch = import.chain(paste(SSTOOLS_ROOT, "/data/liftover/hg19ToHg38.over.chain", sep=""))
    anngr2.GRCh38 = liftOver(gr, ch)
  }else{
    #If the data is 38 (hg38), then the data is already in the right format
    anngr2.GRCh38 <- split(gr, f=1:length(gr))
  }
  anngr2.GRCh38
}

.correct_and_document_failed_variants_LiftOver <- function(gr, pathMissingLocationsFile=NULL, pathMultimappedLocationsFile=NULL){
  le <- elementNROWS(gr)
  if(any(le==0)){
    #write to some outfile for all positions that did not map in lift over
    if(!is.null(pathMissingLocationsFile)){
      dt <- data.table('0'=mcols(gr[le==0])[["ix"]])
      fwrite(dt, file=pathMissingLocationsFile, sep="\t", append=TRUE)
    }
  }
  if(any(le>1)){
    if(!is.null(pathMultimappedLocationsFile)){
      multimapByLiftover <- unlist(gr[le>1])
      dt <- data.table('0'=mcols(multimapByLiftover)[["ix"]])
      fwrite(dt, file=pathMultimappedLocationsFile, sep="\t", append=TRUE)
    }
    #remove them from pipeline
    gr <- gr[le==1]
  }
  gr
}

#quick check to see if provided names are present in header
#check if we have at least one of rsid or chr-pos. 
while(length(line <- readLines(input, n=chunksize)) > 0){
  da <- lapply(strsplit(line, "\t"),function(x){x[cix]})
  spl <- lapply(da, function(x){strsplit(x[1], ":")})
  chr <- suppressWarnings(as.integer(unlist(lapply(spl, function(x){x[[1]][1]}))))
  bp <- suppressWarnings(as.integer(unlist(lapply(spl, function(x){x[[1]][2]}))))
  ix <- suppressWarnings(as.integer(unlist(lapply(da, function(x){x[2]}))))

  # throw out bad input as stderr
  tf <- is.na(chr) | is.na(bp) | is.na(ix)
  
  # throw out bad input 
  if(any(tf)){
    chr <- chr[!tf]
    bp <- bp[!tf]
    ix <- ix[!tf]
  }

  anngr2.GRChX <- GRanges(seqnames=chr, IRanges(bp, width=1), strand="*", ix=ix)
  suppressWarnings(seqlevelsStyle(anngr2.GRChX) <- "UCSC")
  anngr2.GRCh35 <- .coerce_to_GRCh38_from_genome_build_info(anngr2.GRChX, "GRCh35")
  anngr2.GRCh35 <- .correct_and_document_failed_variants_LiftOver(anngr2.GRCh35)
  anngr2.GRCh36 <- .coerce_to_GRCh38_from_genome_build_info(anngr2.GRChX, "GRCh36")
  anngr2.GRCh36 <- .correct_and_document_failed_variants_LiftOver(anngr2.GRCh36)
  anngr2.GRCh37 <- .coerce_to_GRCh38_from_genome_build_info(anngr2.GRChX, "GRCh37")
  anngr2.GRCh37 <- .correct_and_document_failed_variants_LiftOver(anngr2.GRCh37)
  anngr2.GRCh38 <- anngr2.GRChX
  suppressWarnings(seqlevelsStyle(anngr2.GRCh35) <- "NCBI" )
  suppressWarnings(seqlevelsStyle(anngr2.GRCh36) <- "NCBI" )
  suppressWarnings(seqlevelsStyle(anngr2.GRCh37) <- "NCBI" )
  suppressWarnings(seqlevelsStyle(anngr2.GRCh38) <- "NCBI" )

#Paus here (how to map to rsids in the best way?)

    #If the data is 38 (hg38), then the data is already in the right format

    suppressWarnings(seqlevelsStyle(anngr2.GRCh35) <- "NCBI" )
    suppressWarnings(seqlevelsStyle(anngr2.GRCh36) <- "NCBI" )
    suppressWarnings(seqlevelsStyle(anngr2.GRCh37) <- "NCBI" )
    suppressWarnings(seqlevelsStyle(anngr2.GRCh38) <- "NCBI" )
    #suppressWarnings(seqlevelsStyle(anngr2.GRCh38) <- "NCBI" )
    #check which got most hits in rsid annotation database
    rsids.GRCh35 <- snpsByOverlaps(snps, anngr2.GRCh35)
    rsids.GRCh36 <- snpsByOverlaps(snps, anngr2.GRCh36)
    rsids.GRCh37 <- snpsByOverlaps(snps, anngr2.GRCh37)
    rsids.GRCh38 <- snpsByOverlaps(snps, anngr2.GRCh38)
    
    #which has most hits
    lens <- c(length(rsids.GRCh35), length(rsids.GRCh36), length(rsids.GRCh37), length(rsids.GRCh38))
    w <- order(lens, decreasing=TRUE)[1]
    #if 38 contained more hits, then it is 37, and vice versa.
    if(w==1) cat("GRCh35","\t",lens[1],"\t",lens[2],"\t",lens[3],"\t",lens[4],"\n", sep="")
    if(w==2) cat("GRCh36","\t",lens[1],"\t",lens[2],"\t",lens[3],"\t",lens[4],"\n", sep="")
    if(w==3) cat("GRCh37","\t",lens[1],"\t",lens[2],"\t",lens[3],"\t",lens[4],"\n", sep="")
    if(w==4) cat("GRCh38","\t",lens[1],"\t",lens[2],"\t",lens[3],"\t",lens[4],"\n", sep="")
  }else{
    cat("useRSID","\t","---","\t","---","\t","---","\t","---","\n", sep="")
    #for testing which genome build we do not need to map anything
    #AWK_SELECT_BY_COLNAME="modules/awk-modules/select-columns-from-index.awk"
    #text3 <- paste("zcat ", file, " | head -n3000 | gawk -f ", AWK_SELECT_BY_COLNAME, " -v mapcols=\"",rs_ix,"\" -v newcols=\"rs\" | tail -n+2", sep="")
  }
}else{
  cat("mapinfo-not-in-header","\t","---","\t","---","\t","---","\t","---", sep="")
}


