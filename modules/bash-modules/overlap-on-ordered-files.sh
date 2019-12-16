file1=$1
file2=$2

join -t $'\t' -1 1 -2 1 <(cat ${file1}) <(gzip -dc ", ${file2}," ) 
