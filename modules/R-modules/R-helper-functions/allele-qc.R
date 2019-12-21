
# Apply palindrom-filter
.calc_palindrom <- function(a1, a2){
  (a1 == "A" & a2== "T") | (a1 == "T" & a2== "A") | (a1 == "C" & a2== "G") | (a1 == "G" & a2== "C")
}

.opposite_strand <- function(a){
  x <- rep(NA, length(a))
  x[a=="A"] <- "T"
  x[a=="T"] <- "A"
  x[a=="G"] <- "C"
  x[a=="C"] <- "G"
  x
}

.not_expected_a2 <- function(a1,a2,b1,b2,re,al){
  tf1 <- (a1 == re) & (!a2 == al)
  tf2 <- (b1 == re) & (!b2 == al)
  tf1 | tf2
}

.db_possible_pairs <- function(a1,a2, b1, b2, re, al){
  tf1 <- (re == a1 & al == a2)
  tf2 <- (re == b1 & al == b2)
  tf3 <- (re == a2 & al == a1)
  tf4 <- (re == b2 & al == b1)
  tf1 | tf2 | tf3 | tf4
}

.effect_modifier <- function(a1, b1, re){
  ifelse(a1 == re | b1 == re, 1, -1) 
}

