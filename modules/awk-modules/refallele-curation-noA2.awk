#!/usr/bin/awk -f 

#$1 - index
#$2 - A1
#$3 - empty
#$3 - chr:pos
#$4 - rsid
#$5 - ref
#$6 - alt

BEGIN {
  FS = "\t"
  OFS = "\t"
  #send filter cathes to stdError if no file is specified
  if (length(notGCTA) == 0){
    notGCTA="/dev/stderr"
  }
  if (length(indel) == 0){
    indel="/dev/stderr"
  }
  if (length(homvar) == 0){
    homvar="/dev/stderr"
  }
  if (length(palin) == 0){
    palin="/dev/stderr"
  }
  if (length(notExpA2) == 0){
    notExpA2="/dev/stderr"
  }
  if (length(notPossPairs) == 0){
    notPossPairs="/dev/stderr"
  }
 
}


# difference to when having A2
# - no test if in GCTA set
# - no test if A1 and A2 are homozygous (only test on alt and ref)
# - no test if A1 and A2 are palindromes (only test on alt and ref)
# - no test if A2 is the expected (instead we will use the expected A2)
# - no test if A1 and A2 are possible pairs (instead assume they are)

# NOTE: it is advisable to remove multi-allelic sites prior allele correction if using a dataset without A2

{
  # Check if any allele is not in ATGC
  if(!(in_GTCA($2) && in_GTCA($5) && in_GTCA($6))){
    print $0 > notGCTA;
  }else if(indl($5,$6)){
  # Check for homozygote variants (should not happen in real data)
    print $0 > indel;
  }else if(homozygous($5,$6)){
  # Check for homozygote variants (should not happen in real data)
    print $0 > homvar;
  }else if(palindrom($5,$6)){
  # Apply palindrom-filter
    print $0 > palin;
  }else{
  # Use expected A2 as A2 
    a2=calcExpectedA2($2,$5,$6)
  # Calculate effect modifier for remaining and print to stdout
    print $0,effmod($2,a2,$5)
  }
}

