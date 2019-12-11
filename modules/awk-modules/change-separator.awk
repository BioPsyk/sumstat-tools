#!/usr/bin/awk -f 

{for(k=1; k <= NF; k++){printf "%s%s", $(k), OFS } print ""}

