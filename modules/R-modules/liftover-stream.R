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

.coerce_from_GRCh38_to_GRCh37 <- function(gr){
  ch = import.chain(paste(SSTOOLS_ROOT, "/data/liftover/hg38ToHg19.over.chain", sep=""))
  suppressWarnings(seqlevelsStyle(gr) <- "UCSC")
  liftOver(gr, ch)
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

input<-file('stdin', 'r')
#input<-file(file, 'r')

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

  # Potentially any format GRCh36, GRCh37 or GRCh38
  anngr2.GRChX <- GRanges(seqnames=chr, IRanges(bp, width=1), strand="*", ix=ix)
  # Coerce to GRCh38 depending provided the correct present genomebuild
  if((gbin=="GRCh35" | gbin=="GRCh36" | gbin=="GRCh37") & gbout=="GRCh38"){
    anngr2.GRCh38 <- .coerce_to_GRCh38_from_genome_build_info(anngr2.GRChX, gbin)
    anngr2.GRCh38 <- .correct_and_document_failed_variants_LiftOver(anngr2.GRCh38, path_missing_position_file, path_multimapped_file)
    anngr2.out <- unlist(anngr2.GRCh38)
  }else if(gbin=="GRCh38" & gbout=="GRCh37"){
    anngr2.GRCh37 <- .coerce_from_GRCh38_to_GRCh37(anngr2.GRChX)
    anngr2.GRCh37 <- .correct_and_document_failed_variants_LiftOver(anngr2.GRCh37, path_missing_position_file, path_multimapped_file)
    anngr2.out <- unlist(anngr2.GRCh37)
  }else{
    stop("This conversion is not implemented")
  }
  # Write to stdout the line that survived all filters and got a modifier
  suppressWarnings(seqlevelsStyle(anngr2.out) <- "NCBI" )
  chrpos <- paste(seqnames(anngr2.out),":",start(anngr2.out),sep="")
  inx <- mcols(anngr2.out)[["ix"]]
  for(i in 1:length(chrpos)){
    cat(chrpos[i], inx[i], "\n", append=FALSE, sep="\t")
  }
}

