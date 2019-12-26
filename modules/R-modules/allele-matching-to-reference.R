args = commandArgs(trailingOnly=TRUE)

Rhelpers=args[1]
whichinx=args[2]
#whichinx="a1=1,a2=2,d1=4,d2=5"
spl <- unlist(strsplit(whichinx, ","))
spl2 <- strsplit(spl, "=")
args <- unlist(lapply(spl2,FUN=function(x){x[1]}))
vals <- as.integer(unlist(lapply(spl2,FUN=function(x){x[2]})))
names(vals) <- args
cix=c(vals[["a1"]], vals[["a2"]], vals[["d1"]], vals[["d2"]],vals[["inx"]])

source(paste(Rhelpers,"/allele-qc.R",sep=""))

input<-file('stdin', 'r')
#line <- c("A","C","ix","C","A")
#line <- paste(line, collapse="\t")
while(length(line <- readLines(input, n=1)) > 0){
  el <- unlist(strsplit(line, "\t"))[cix]
  
  # To simplify subsetting, collect vectors in data.frame
  #df <- data.frame(A1=A1, A2=A2, ref=ref ,alt=alt, stringsAsFactors=FALSE)
  
  # Check for NA 
  tf <- is.na(el[1]) | is.na(el[2]) | is.na(el[3]) | is.na(el[4])
  if(tf){
    write(paste(el[5], "NAs", sep="\t"), stderr())
    next
  }

  # Check for nucleotide not in A, T, G or C
  tf <- (!(el[1] %in% c("A","T","G","C"))) | (!(el[2] %in% c("A","T","G","C"))) | (!(el[3] %in% c("A","T","G","C"))) | (!(el[4] %in% c("A","T","G","C")))
  if(tf){
    write(paste(el[5], "notGCTA", sep="\t"), stderr())
    next
  }
  # Check for homozygote variants (should not happen in real data)
  tf <- el[1] == el[2]
  if(tf){
    write(paste(el[5], "hom", sep="\t"), stderr())
    next
  }
  tf <- el[3] == el[4]
  if(tf){
    write(paste(el[5], "hom", sep="\t"), stderr())
    next
  }
  
  # Apply palindrom-filter
  tf1 <- .calc_palindrom(el[1],el[2])
  tf2 <- .calc_palindrom(el[3], el[4])
  if(tf1|tf2){
    write(paste(el[5], "palindrom", sep="\t"), stderr())
    next
  }
  
  # Calculate opposite strand eqivalent
  B1 <- .opposite_strand(el[1])
  B2 <- .opposite_strand(el[2])
  
  # Check for not expected A2:s. In real data we should have very few non expected A2s (in any case, exclude them)
  tf3 <- .not_expected_a2(el[1], el[2], B1, B2, el[3], el[4])
  if(tf3){
    write(paste(el[5], "notExpA2", sep="\t"), stderr())
    next
  }
  
  # Find the only logically possible pairs, all other are excluded (should not be non-possible pairs in real data)
  tf4 <- .db_possible_pairs(el[1], el[2], B1, B2, el[3], el[4])
  if(!tf4){
    write(paste(el[5], "notPossible", sep="\t"), stderr())
    next
  }
  
  # Now we are ready to calculate the effect modifier (assumes all filters above have been applied)
  em <- .effect_modifier(el[1], B1, el[3])
  
  # write to stdout the line that survived all filters and got a modifier
  write(paste(el[5], el[3], el[4], em, sep="\t"), stdout())
}

