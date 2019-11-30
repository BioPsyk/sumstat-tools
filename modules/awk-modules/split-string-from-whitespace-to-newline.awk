#!/usr/bin/awk -f 

BEGIN {
    #only allow tab separated input
    FS = "\t"
    #Specify out field separator
    OFS = "\t"
}

{
  for(i = 1; i <= NF; i++) { 
    print $i; 
  }
}
