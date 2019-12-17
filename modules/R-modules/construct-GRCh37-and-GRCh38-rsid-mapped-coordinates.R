################################################################################
# retrieve arguments
################################################################################

args = commandArgs(trailingOnly=TRUE)

libdir=args[1]
chr_ix=args[2]
bp_ix=args[3]
rs_ix=args[4]
file=args[5]
gb=args[6]
outDir=args[7]
SSTOOLS_ROOT=args[8]

#Arguments retrieved
message(paste("-------------------------------------",sep=""))
message(paste(" Command line inputs are the following:",sep=""))
message(paste("-------------------------------------",sep=""))
message(paste("libdir: ", libdir,sep=""))
message(paste("chr_ix: ",chr_ix,sep=""))
message(paste("bp_ix: ",bp_ix,sep=""))
message(paste("rs_ix: ",rs_ix,sep=""))
message(paste("file: ",file,sep=""))
message(paste("gb: ",gb,sep=""))
message(paste("outdir: ",outDir,sep=""))
message(paste("SSTOOLS_ROOT: ",SSTOOLS_ROOT,sep=""))
message(paste("-------------------------------------",sep=""))
message(paste(" Starting script",sep=""))
message(paste("-------------------------------------",sep=""))

################################################################################
# argument check
################################################################################


################################################################################
# support functions
################################################################################

.check_if_the_rsid_mapper_reported_more_than_one_rsid <- function(gr){
    le2 <- unlist(lapply(mcols(gr)[["RefSNP_id"]], length))
    if(!all(sum(le2==1))){stop("We need to implement a way to handle snps that map to several rsids, cause it just happened")}
}

# get rsids for gr from dbsnp object 'snps' (keeping index information)
.get_rsid_from_location <- function(gr, snps){
  #check rsid annotation database
  suppressWarnings(seqlevelsStyle(gr) <- "NCBI" )
  rsids.GRCh38 <- snpsByOverlaps(snps, gr)
  #calculate overlap 
  hits <- findOverlaps(rsids.GRCh38, gr)
  #add index to keep track of how the result relates to the original data
  mcols(rsids.GRCh38)[["ix"]] <- mcols(gr)[["ix"]][subjectHits(hits)]
  #check for a case we are not handling right now, stop if it happens
  .check_if_the_rsid_mapper_reported_more_than_one_rsid(rsids.GRCh38)
  #return object
  rsids.GRCh38
}

# 
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


.correct_and_document_failed_variants_LiftOver <- function(gr, pathMissingLocationsFile, pathMultimappedLocationsFile){
  le <- unlist(lapply(gr, length))
  if(any(le==0)){
    #write to some outfile for all positions that did not map in lift over
    goneByLiftover <- gr[le==0]
    dt <- data.table(ix=mcols(goneByLiftover)[["ix"]], CHR=sub("chr","", as.character(seqnames(goneByLiftover)), ignore.case=TRUE), POS=start(goneByLiftover))
    fwrite(dt, file=pathMissingLocationsFile, sep="\t")
  }
  if(any(le>1)){
    #write to some outfile for all positions that did map to multiple positions in lift over (then discard)
    multimapByLiftover <- unlist(gr[le>1])
    dt <- data.table(ix=mcols(multimapByLiftover)[["ix"]], CHR=sub("chr","", as.character(seqnames(multimapByLiftover)), ignore.case=TRUE), POS=start(multimapByLiftover))
    fwrite(dt, file=pathMultimappedLocationsFile, sep="\t")
    #remove them from pipeline
    gr <- gr[le==1]
  }
  gr
}

.print_to_file_locations_missing_rsid <- function(gr, pathToMissingRsidFile){
  dt <- data.table(ix=mcols(gr)[["ix"]], CHR=sub("chr","", as.character(seqnames(gr)), ignore.case=TRUE), POS=start(gr))
  fwrite(dt, file=pathToMissingRsidFile, sep="\t")
}
.print_to_file_locations_having_rsid <- function(gr, pathToFoundRsidFile){
  dt <- data.table(ix=mcols(gr)[["ix"]], CHR=sub("chr","", as.character(seqnames(gr)), ignore.case=TRUE), POS=start(gr), dbSNP151=mcols(gr)[["RefSNP_id"]], REF=as.character(mcols(gr)[["REF"]]), ALT=as.character(mcols(gr)[["ALT"]]))
  fwrite(dt, file=pathToFoundRsidFile, sep="\t")
}

fetchColFromFile <- function(file, field_ix){
  #use special awk split function
  AWK_SELECT_BY_COLNAME=paste(SSTOOLS_ROOT, "/modules/awk-modules/select-columns-from-index.awk", sep="")
  text1 <- paste("zcat ", file, " | head -n1000 | gawk -f ", AWK_SELECT_BY_COLNAME, " -v mapcols=\"",field_ix,"\" -v newcols=\"",field_ix,"\" | tail -n+2", sep="")
  system(text1, intern=TRUE)
}

.getHeaderFromFile <- function(file){
  AWK_SPLIT_TO_NEWLINE=paste(SSTOOLS_ROOT, "/modules/awk-modules/split-string-from-whitespace-to-newline.awk", sep="")
  text0 <- paste("zcat ", file, " | head -n1 | awk -f ", AWK_SPLIT_TO_NEWLINE, sep="")
  header <- system(text0, intern=TRUE)
  header
}

#rsid branch specific functional units
.scan_for_entries_not_having_rs_prefix <- function(rsids){
  grepl("rs", rsids, ignore.case=TRUE)
}

.map_rsid_to_position <- function(rsids, ix, snps){
  rsids.GRCh38 <- snpsById(snps, rsids, ifnotfound="drop")
  #align index
  newrs <- mcols(rsids.GRCh38)[["RefSNP_id"]]
  tf1 <- newrs %in% rsids
  tf2 <- rsids %in% newrs
  if(all(tf1) & sum(tf2)==length(newrs)){ 
    mcols(rsids.GRCh38)[["ix"]] <- ix[match(newrs, rsids)]
  }else{ 
    stop("unexpected behaviour of snpsById, our assumption that same rsids used as arguments will be present and re-used in newrs seems to be wrong")
  }
  rsids.GRCh38
}

print_to_file_rsids_that_did_not_map_to_position <- function(new, old, oldix, outfile){
  tf <- old%in%new
  fwrite(data.table(ix=oldix[!tf], RSID=old[!tf]), file=outfile, sep="\t")
}

################################################################################
# Main function
################################################################################

coerceToGRCh38andGRCh37 <- function(libdir,chr_ix,bp_ix,rs_ix,file,gb,outDir, verbose){
    
  #Differences between GRCh38(hg19) and GRCh38
  #https://www.sciencedirect.com/science/article/pii/S0888754317300058
  
  #prepare output base filename (only the filename not the path)
  basename <- sub(".txt.gz", "", gsub(".*/", "", file))
  message(paste("basename is set to: ", basename, sep=""))

  #create outfile directories if they are missing
  system(paste("mkdir -p ",outDir,"/successfull_mappings", sep=""))
  system(paste("mkdir -p ",outDir,"/successfull_mappings/GRCh37", sep=""))
  system(paste("mkdir -p ",outDir,"/successfull_mappings/GRCh38", sep=""))
  system(paste("mkdir -p ",outDir,"/failed_mappings", sep=""))
  system(paste("mkdir -p ",outDir,"/failed_mappings/liftOverFilter", sep=""))
  system(paste("mkdir -p ",outDir,"/failed_mappings/no_rsid_for_coordinates", sep=""))
  system(paste("mkdir -p ",outDir,"/failed_mappings/no_coordinates_for_rsid", sep=""))
  system(paste("mkdir -p ",outDir,"/failed_mappings/RSID_badname", sep=""))
  
  #liftover failures (going to GRCh38)
  path_missing_position_file <- paste(outDir, "/failed_mappings/liftOverFilter/missing_1_", basename, ".txt", sep="")
  path_multimapped_file <- paste(outDir, "/failed_mappings/liftOverFilter/multimapped_1_", basename, ".txt", sep="")
  
  #no map to rsid
  path_to_missing_rsid_file <- paste(outDir, "/failed_mappings/no_rsid_for_coordinates/noRSID_", basename, ".txt", sep="")

  #liftover failures (back to GRCh37)
  path_missing_position_file_GRCh37 <- paste(outDir, "/failed_mappings/liftOverFilter/missing_2_", basename, ".txt", sep="")
  path_multimapped_fileGRCh37 <- paste(outDir, "/failed_mappings/liftOverFilter/multimapped_2_", basename, ".txt", sep="")

  #successes
  path_to_successfull_mappings_file_37 <- paste(outDir, "/successfull_mappings/GRCh37/remaining_", basename, ".txt", sep="")
  path_to_successfull_mappings_file_38 <- paste(outDir, "/successfull_mappings/GRCh38/remaining_", basename, ".txt", sep="")
  
  #paths probably only used in the from rsid branch (but could happen to chr and bp also I guess)
  rsid_badname_file <- paste(outDir, "/failed_mappings/RSID_badname/RSID_badname_", basename, ".txt", sep="")
  path_to_missing_location_file <- paste(outDir, "/failed_mappings/no_coordinates_for_rsid/noCoord_", basename, ".txt", sep="")

  
  #select correct library
  .libPaths(libdir)
  
  #read header
  header <- .getHeaderFromFile(file)
  
  #quick check to see if provided names are present in header (the check can handle funx names)
  if(grepl("funx", chr_ix)){ chr_tf <- sub(".$","",sub(".*\\(","",chr_ix)) %in% header
  }else{ chr_tf <- chr_ix %in% header}
  if(grepl("funx", bp_ix)){ bp_tf <- sub(".$","",sub(".*\\(","",bp_ix)) %in% header
  }else{ bp_tf <- bp_ix %in% header}
  if(grepl("funx", rs_ix)){ rs_tf <- sub(".$","",sub(".*\\(","",rs_ix)) %in% header
  }else{ rs_tf <- rs_ix %in% header}
  
  if (chr_tf & bp_tf | rs_tf){
    message(paste("enough field info is present to start", sep=""))
    #load packages
    message(paste("loading packages", sep=""))
    suppressMessages(library("SNPlocs.Hsapiens.dbSNP151.GRCh38"))
    snps <- SNPlocs.Hsapiens.dbSNP151.GRCh38
    suppressMessages(library(liftOver))
    suppressMessages(library(data.table))
  
    if (chr_tf  & bp_tf){
      message(paste("chr and bp info exists, therefore use that", sep=""))
      message(paste("reading chr and bp info, and setting inital index", sep=""))
      chr <- sub("\t","", fetchColFromFile(file, chr_ix))
      bp <- as.integer(sub("\t","", fetchColFromFile(file, bp_ix)))
      ix <- 1:length(bp)
  
      #Add this line when testing for what happens when a position can't be lifted over (here from the chrom end, which is badly mapped in hg19)
      #bp[1] <- 249250621
      #bp[5] <- 249250621
      
      #Potentially any format GRCh36, GRCh37 or GRCh38
      anngr2.GRChX <- GRanges(seqnames=chr, IRanges(bp, width=1), strand="*", ix=ix)
  
      message(paste("coerce to GRCh38 depending provided the correct present genomebuild", sep=""))
      anngr2.GRCh38 <- .coerce_to_GRCh38_from_genome_build_info(anngr2.GRChX, gb)
  
      #Add this line when testing what happens when a position gets multimapped
      #anngr2.GRCh38[[4]] <- c(anngr2.GRCh38[[4]], anngr2.GRCh38[[4]])
  
      message(paste("Check for map problems, if so correct data and report to declared outfiles", sep=""))
      anngr2.GRCh38 <- .correct_and_document_failed_variants_LiftOver(anngr2.GRCh38, path_missing_position_file, path_multimapped_file)
  
      message(paste("now we only have perfect matches from liftover and can therefore unlist the object", sep=""))
      anngr2.GRCh38 <- unlist(anngr2.GRCh38)
  
      message(paste("get rsid from 'snps' database object", sep=""))
      rsids.GRCh38 <- .get_rsid_from_location(anngr2.GRCh38, snps)

      message(paste("print to file all positions which did not have corresponding rsid", sep=""))
      .print_to_file_locations_missing_rsid(anngr2.GRCh38[-mcols(rsids.GRCh38)[["ix"]]], path_to_missing_rsid_file)
      
  
      message(paste("print to file all positions which had corresponding rsid", sep=""))
      .print_to_file_locations_having_rsid(rsids.GRCh38, path_to_successfull_mappings_file_38)
  
      message(paste("As a final major step we here liftOver back to GRCh37", sep=""))
      rsids.GRCh37 <- .coerce_from_GRCh38_to_GRCh37(rsids.GRCh38)
  
      message(paste("map problems Round two (as we now are mapping back to GRCh37 and GRCh38 original genome build might not always map)", sep=""))
      rsids.GRCh37 <- .correct_and_document_failed_variants_LiftOver(rsids.GRCh37, path_missing_position_file_GRCh37, path_multimapped_file_GRCh37)

      message(paste("now we only have perfect matches from liftover and can therefore unlist the object", sep=""))
      rsids.GRCh37 <- unlist(rsids.GRCh37)
  
      message(paste("now write GRCh37 to file", sep=""))
      .print_to_file_locations_having_rsid(rsids.GRCh37, path_to_successfull_mappings_file_37)
  
      cat("mapping to GRCh37, GRCh38 and RSIDs complete for ", basename ,"\n")
      
    }else{

      message(paste("Starting with RSIDs as input the workflow will be slightly different than starting from position", sep=""))
      rsids <- sub("\t","", fetchColFromFile(file, rs_ix))
      ix <- 1:length(rsids)
  
      message(paste("first step is to separate snps not starting with rs)", sep=""))
      tf <- .scan_for_entries_not_having_rs_prefix(rsids)
      
      message(paste("check if we need to go through different branches", sep=""))
      if(any(tf)){rsids2 <- rsids[tf]; rix=ix[tf]; realExist=TRUE}else{realExist=FALSE}
      if(!all(tf)){other <- rsids[!tf]; oix=ix[!tf]; otherExist=TRUE}else{otherExist=FALSE}
  
      message(paste("write non rs-prefix to file. in theory we could send them into the mapping system using chr:bp (not implemented yet)", sep=""))
      if(otherExist){fwrite(data.table(ix=oix, RSID=other), file=rsid_badname_file, sep="\t")}
  
      message(paste("for all rsids with the prefix rs, start the process", sep=""))
      if(realExist){
        message(paste("map to position (takes time)", sep=""))
        rsids.GRCh38 <- .map_rsid_to_position(rsids2, ix=rix, snps)
  
        message(paste("print all rsids2 that did not map to a position", sep=""))
        print_to_file_rsids_that_did_not_map_to_position(mcols(rsids.GRCh38)[["RefSNP_id"]], rsids2, rix, path_to_missing_location_file)
  
        message(paste("map back to rsids from location, to be sure we use the same rsid base among all sumstat files", sep=""))
        rsids.GRCh38 <- .get_rsid_from_location(granges(rsids.GRCh38), snps)

        message(paste("print to file all positions which had corresponding rsid", sep=""))
        .print_to_file_locations_having_rsid(rsids.GRCh38, path_to_successfull_mappings_file_38)
  
        message(paste("As a final major step we here liftOver back to GRCh37", sep=""))
        rsids.GRCh37 <- .coerce_from_GRCh38_to_GRCh37(rsids.GRCh38)
  
        message(paste("map problems Round two (as we now are mapping back to GRCh37 and GRCh38 original genome build might not always map)", sep=""))
        rsids.GRCh37 <- .correct_and_document_failed_variants_LiftOver(rsids.GRCh37, path_missing_position_file_GRCh37, path_multimapped_file_GRCh37)

        message(paste("now we only have perfect matches from liftover and can therefore unlist the object", sep=""))
        rsids.GRCh37 <- unlist(rsids.GRCh37)
  
        #now write GRCh37 to file
        message(paste("now write GRCh37 to file", sep=""))
        .print_to_file_locations_having_rsid(rsids.GRCh37, path_to_successfull_mappings_file_37)
  
        cat("mapping to GRCh37, GRCh38 and RSIDs complete for ", basename ,"\n")
      } 
    }
  }else{
    message(paste("ERROR: no index provided is present in file, not possible to map GRCh37, GRCh38 and RSIDs for ", basename ,"\n", sep=""))
  }
}

################################################################################
# Run the code using command line arguments
################################################################################

#run function
coerceToGRCh38andGRCh37(
libdir=libdir,
chr_ix=chr_ix,
bp_ix=bp_ix,
rs_ix=rs_ix,
file=file,
gb=gb,
outDir=outDir,
verbose=verbose
)

################################################################################
# Testing, can be moved to more specific integrity tests in the future
################################################################################
#if on HPC
#module load intel/perflibs/64
#module load R/3.6.1

#libdir="/home/projects/cu_10009/general/R-libraries/R_3.6.1_Bioc_3.10_library"
#libdir="/home/projects/cu_10009/general/R-libraries/R_3.6.1_Bioc_3.9_library"
##simple case
#chr_ix <- "Chrom"
#bp_ix <- "Pos"
#rs_ix <- "Marker"
#file <- "tests/testdata/gwas-summary-stats/Fritsche-26691988.txt.gz"
#gb <- "GRCh37"
#outDir <- "tests/testdata/02_genomic_information_to_add"

#another with not all mapping in liftover
#chr_ix <- "CHR"
#bp_ix <- "BP"
#rs_ix <- "SNP"
#file <- "tests/testdata/01_format_corrected_sumstats/AD_sumstats_Jansenetal.txt.gz"
#gb <- "GRCh37"
#outDir <- "tests/testdata/02_genomic_information_to_add"
#

#another one using funx argument
#chr_ix <- "funx_CHR_BP_2_CHR(MarkerName)"
#bp_ix <- "funx_CHR_BP_2_BP(MarkerName)"
#rs_ix <- "rsID"
#file <- "tests/testdata/gwas-summary-stats/t2d_dom_dev.txt.gz"

