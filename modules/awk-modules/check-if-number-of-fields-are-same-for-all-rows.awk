#!/usr/bin/awk -f 

#BEGIN {FS="[ \t]+"}
BEGIN {FS="\t"}
NR==1 {comp=NF}
NF!=comp {rows=+1}
END {
  if (rows==0){ print "good", filename}
  if (rows!=0){ print "bad", filename }
}

