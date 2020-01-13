#!/usr/bin/awk -f 

#$1 - index
#$2 - A1
#$3 - A2
#$4 - empty
#$5 - chr:pos
#$6 - rsid
#$7 - ref
#$8 - alt

BEGIN {
  FS = "\t"
  OFS = "\t"
  #send filter cathes to stdError if no file is specified
  if (length(notGCTA) == 0){
    notGCTA="/dev/stderr"
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

# Check if any is not in ATGC
{
  if(!(in_GTCA($2) && in_GTCA($3) && in_GTCA($7) && in_GTCA($8))){
    print $0 > notGCTA;
  }else if(homozygous($2,$3) || homozygous($7,$8)){
  # Check for homozygote variants (should not happen in real data)
    print $0 > homvar;
  }else if(palindrom($2,$3) || palindrom($7,$8)){
  # Apply palindrom-filter
    print $0 > palin;
  }else if(notExpectedA2($2,$3,opp($2),opp($3),$7,$8)){
  # Not expected A2
    print $0 > notExpA2;
  }else if(!possiblePairs($2,$3,opp($2),opp($3),$7,$8)){
  # Not Possible Pairs
    print $0 > notPossPairs;
  }else{
  # Calculate effect modifier for remaining and print to stdout
    print $0,effmod($2,$3,$7)
  }
}

