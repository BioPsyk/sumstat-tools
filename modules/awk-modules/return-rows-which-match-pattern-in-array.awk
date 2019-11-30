#!/usr/bin/awk -f 

BEGIN {
    #check only for tab separated entries
    FS = "\t"
    #Specify out field separator
    OFS = "\t"
    # split the input variable columns and store as out
    split(idsX,idsY,",")
}

NR>1 {
    for(j=1; j <= length(idsY); j++){
      #printf "%s%s", idsY[j], OFS
      #if ($1 ~ /idsY[j]/) {
      #if ($1 == "age-related_macular_degeneration_29566793") {
      if ($1 == idsY[j]) {
        print $1,$3
      }
    }
}

