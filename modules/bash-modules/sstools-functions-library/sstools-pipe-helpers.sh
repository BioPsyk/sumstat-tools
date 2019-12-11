function readoption() {
  if [ "${1}" == "-" ]; then
   cat 
  elif [ "${1: -3}" == ".gz" ]; then
    zcat ${1}
  else 
    cat ${1}
  fi
}

function basename_stream() {
  while read line; do
    basename $line
  done
}

function comma2newline() {
  while read line; do
    echo $line | awk '{gsub(" *, *","\n",$0); print $0}'
  done
}

function newline2symbol() {
  while read line; do echo $line; done | paste -s -d${1}
}


