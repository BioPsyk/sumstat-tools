# Make example data from random data-points
set.seed(1)
A1 <- paste(sample(c("T","G","C"), 10000, replace=TRUE), "A", sep="-")
T1 <- paste(sample(c("A","G","C"), 10000, replace=TRUE), "T", sep="-")
G1 <- paste(sample(c("T","A","C"), 10000, replace=TRUE), "C", sep="-")
C1 <- paste(sample(c("T","G","A"), 10000, replace=TRUE), "G", sep="-")

ss <- c(A1,T1,G1,C1)
db <- sample(ss)
ss <- sample(ss)

# Split data to resemble real data
A1 <- unlist(lapply(strsplit(ss, "-"), function(x){x[1]}))
A2 <- unlist(lapply(strsplit(ss, "-"), function(x){x[2]}))
ref <- unlist(lapply(strsplit(db, "-"), function(x){x[1]}))
alt <- unlist(lapply(strsplit(db, "-"), function(x){x[2]}))

# To simplify subsetting, collect vectors in data.frame
df <- data.frame(A1=A1,A2=A2,ref=ref,alt, stringsAsFactors=FALSE)

# Add some NAs
df$A1[c(4,234,4534)] <- NA

# Add some nucleotides not within the set of A, T, G or C
df$A2[c(10,544,3234)] <- c("X","PO","?")

# Check for NA 
tf <- is.na(df$A1) | is.na(df$A2) | is.na(df$ref) | is.na(df$alt)
df <- df[!tf,]

# Check for nucleotide not in A, T, G or C
tf0 <- (!(df$A1 %in% c("A","T","G","C"))) | (!(df$A2 %in% c("A","T","G","C"))) | (!(df$ref %in% c("A","T","G","C"))) | (!(df$alt %in% c("A","T","G","C")))
df <- df[!tf0,]

# Check for homozygote variants (should not happen in real data)
tf00 <- df$A1 == df$A2
df <- df[!tf00,]
tf000 <- df$ref == df$alt
df <- df[!tf000,]

# Apply palindrom-filter
.calc_palindrom <- function(a1, a2){
  (a1 == "A" & a2== "T") | (a1 == "T" & a2== "A") | (a1 == "C" & a2== "G") | (a1 == "G" & a2== "C")
}
tf1 <- .calc_palindrom(df$A1,df$A2)
tf2 <- .calc_palindrom(df$ref, df$alt)
df <- df[!(tf1|tf2),]

# Calculate opposite strand eqivalent
.opposite_strand <- function(a){
  x <- rep(NA, length(a))
  x[a=="A"] <- "T"
  x[a=="T"] <- "A"
  x[a=="G"] <- "C"
  x[a=="C"] <- "G"
  x
}

df$B1 <- .opposite_strand(df$A1)
df$B2 <- .opposite_strand(df$A2)

# Check for not expected A2:s
.not_expected_a2 <- function(a1,a2,b1,b2,re,al){
  tf1 <- (a1 == re) & (!a2 == al)
  tf2 <- (b1 == re) & (!b2 == al)
  tf1 | tf2
}
# In real data we should have very few non expected allele pairs (in any case, exclude them)
tf3 <- .not_expected_a2(df$A1, df$A2, df$B1, df$B2, df$ref, df$alt)
df <- df[!tf3,]

# find the only logically possible pairs (all other are excluded if it happens)
.db_possible_pairs <- function(a1,a2, b1, b2, re, al){
  tf1 <- (re == a1 & al == a2)
  tf2 <- (re == b1 & al == b2)
  tf3 <- (re == a2 & al == a1)
  tf4 <- (re == b2 & al == b1)
  tf1 | tf2 | tf3 | tf4
}
tf4 <- .db_possible_pairs(df$A1, df$A2, df$B1, df$B2, df$ref, df$alt)
df <- df[tf4,]

# Now we are ready to calculate the effect modifier (assumes the .not_expected_a2 test has been run and all filters above have been applied)
.effect_modifier <- function(a1, re){
  ifelse(a1 == re, 1, -1) 
}

em <- .effect_modifier(df$A1, df$ref)

df$em <- em

# Check distribution
table(em)

