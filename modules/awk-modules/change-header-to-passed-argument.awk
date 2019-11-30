#!/usr/bin/awk -f 
BEGIN {
    #Specify out field separator
    OFS = "\t"
    # split the input variable columns and store as out
    split(newHeader,headerout,",")
}

# visit only first line first
NR==1 {
    #print new header
    for(k=1; k < length(headerout); k++){
      printf "%s%s", headerout[k], OFS
    }
    printf "%s", headerout[length(headerout)]
    print ""
}

#print the rest unmodified
NR>1 {print $0}

