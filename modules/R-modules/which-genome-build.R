
#if on HPC
#module load intel/perflibs/64
#module load R/3.6.1

args = commandArgs(trailingOnly=TRUE)

libdir=args[1]
chr_ix=args[2]
bp_ix=args[3]
rs_ix=args[4]
file=args[5]

#libdir="/home/projects/cu_10009/general/R-libraries/R_3.6.1_Bioc_3.10_library"
#
##simple case
#chr_ix <- "Chrom"
#bp_ix <- "Pos"
#rs_ix <- "Marker"
#file <- "tests/testdata/gwas-summary-stats/Fritsche-26691988.txt.gz"
#
##using funx argument
#chr_ix <- "funx_CHR_BP_2_CHR(MarkerName)"
#bp_ix <- "funx_CHR_BP_2_BP(MarkerName)"
#rs_ix <- "rsID"
#file <- "tests/testdata/gwas-summary-stats/t2d_dom_dev.txt.gz"

#read in header to scan for field
#text0 <- paste("zcat ", file, " | head -n1 | awk -F\"t\" {BEGIN{OFS=\"t\"}; for \(i=1; i<=NF; i++\) printf \"%s%s\",$\(i\),OFS;  }' ")
#text0 <- paste("zcat ", file, " | head -n1 | awk \'{BEGIN{FS=\"\\t\"; OFS=\"\\t\"}; print $\(1\) }\' ")
#text0 <- paste("zcat ", file, " | head -n1 | awk \'{print $\(1\) }\' ", sep="")
#header <- unlist(strsplit(system(text0, intern=TRUE), split="\t"))

#select correct library
.libPaths(libdir)

#read header
AWK_SPLIT_TO_NEWLINE="modules/awk-modules/split-string-from-whitespace-to-newline.awk"
text0 <- paste("zcat ", file, " | head -n1 | awk -f ", AWK_SPLIT_TO_NEWLINE, sep="")
header <- system(text0, intern=TRUE)

#quick check to see if provided names are present in header
#the check can handle funx names
if(grepl("funx", chr_ix)){
  chr_tf <- sub(".$","",sub(".*\\(","",chr_ix)) %in% header
}else{
  chr_tf <- chr_ix %in% header
}
if(grepl("funx", bp_ix)){
  bp_tf <- sub(".$","",sub(".*\\(","",bp_ix)) %in% header
}else{
  bp_tf <- bp_ix %in% header
}
if(grepl("funx", rs_ix)){
  rs_tf <- sub(".$","",sub(".*\\(","",rs_ix)) %in% header
}else{
  rs_tf <- rs_ix %in% header
}


#check if we have at least one of rsid or chr-pos. 
if (chr_tf & bp_tf | rs_tf){
  #load packages
  suppressMessages(library("SNPlocs.Hsapiens.dbSNP151.GRCh38"))
  snps <- SNPlocs.Hsapiens.dbSNP151.GRCh38
  suppressMessages(library(liftOver))

  #if chr and bp exist, we use them otherwise we use rsid
  if (chr_tf  & bp_tf){
    
    #use special awk split function
    AWK_SELECT_BY_COLNAME="modules/awk-modules/select-columns-from-index.awk"
    text1 <- paste("zcat ", file, " | head -n1000 | gawk -f ", AWK_SELECT_BY_COLNAME, " -v mapcols=\"",chr_ix,"\" -v newcols=\"chr\" | tail -n+2", sep="")
    text2 <- paste("zcat ", file, " | head -n1000 | gawk -f ", AWK_SELECT_BY_COLNAME, " -v mapcols=\"",bp_ix,"\" -v newcols=\"bp\" | tail -n+2", sep="")
    #text1 <- paste("zcat ", file, " | head -n3000 | tail -n+2 | awk '{print $",chr_ix2,"}' ")
    #text2 <- paste("zcat ", file, " | head -n3000 | tail -n+2 | awk '{print $",bp_ix2,"}' ")
    chr <- as.integer(system(text1, intern=TRUE))
    bp <- as.integer(system(text2, intern=TRUE))
    
    #Potentially any format GRCh36, GRCh37 or GRCh38
    anngr2.GRChX <- GRanges(seqnames=chr, IRanges(bp, width=1), strand="*")
    suppressWarnings(seqlevelsStyle(anngr2.GRChX) <- "UCSC")

    #If the data is 35 (hg17), then this is the right procedure
    ch = import.chain("/home/people/jesgaa/2019-10-14-simple-andres-ldpred-run/data/extra/hg17ToHg38.over.chain")
    anngr2.GRCh35 = unlist(liftOver(anngr2.GRChX, ch))

    #If the data is 36 (hg18), then this is the right procedure
    ch = import.chain("/home/people/jesgaa/2019-10-14-simple-andres-ldpred-run/data/extra/hg18ToHg38.over.chain")
    anngr2.GRCh36 = unlist(liftOver(anngr2.GRChX, ch))
    
    #If the data is 37 (hg19), then this is the right procedure
    ch = import.chain("/home/people/jesgaa/2019-10-14-simple-andres-ldpred-run/data/extra/hg19ToHg38.over.chain")
    anngr2.GRCh37 = unlist(liftOver(anngr2.GRChX, ch))

    #If the data is 38 (hg38), then the data is already in the right format
    anngr2.GRCh38 <- anngr2.GRChX

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
  cat("---","\t","---","\t","---","\t","---","\t","---", sep="")
}


