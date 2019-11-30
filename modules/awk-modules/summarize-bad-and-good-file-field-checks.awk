#!/usr/bin/awk -f 

{count[$1]++} 

END{print "there were", count["good"], "good files, and,", count["bad"], "bad files"}

