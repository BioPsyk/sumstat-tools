function grep_from_mapfile() {
  file=$1
  field=$2
  invert=$3
  names=$4


  if $names ; then
    cmd="cat ${file}"
  else
    cmd="tail -n+2 ${file}"
  fi
  cmd="${cmd} | awk -vfield=${field} '{print \$field}' "

  if $invert ; then
    cmd="${cmd} | egrep -v"
  else
    cmd="${cmd} | egrep"
  fi
  read data
  eval "${cmd} '${data}'"
}

#echo "DIAG" | grep_from_mapfile $file $field false false
#echo "DIAG" | grep_from_mapfile $file $field true false
#echo "DIAG|dom" | grep_from_mapfile $file $field true false

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

#echo "roligt/hej1,DIAG, hej3" | comma2newline | basename_stream | newline2symbol '|' | grep_from_mapfile $file $field $invert $names

function interactiveWalkerMultiple() {

  filepaths=$1
  mapout=$2
  newheader=$3
  SSTOOLS_ROOT=$4

  if [ -f ${mapout} ]; 
  then
    #get mapfile names
    regformat="$(echo "$filepaths" | comma2newline | basename_stream | newline2symbol '|' )"
    filenamessalready=($(echo "$regformat" | grep_from_mapfile $mapout 1 FALSE FALSE))
    filenamesremain=($(echo "$regformat" | grep_from_mapfile $mapout 1 TRUE FALSE))

    #get full path
    regformat2="$(for line in "${filenamesremain[@]}"; do echo $line | newline2symbol '|' )"
    filepathsremain=$(echo "$filepaths" | comma2newline | grep $regformat2)
    filepathsremainlength=${#filepathsremain[@]}
  else
    #if maput does not exist we can safely use all avail filenames
    filepathsremain=${filepaths}
    filepathsremainlength=${#filepaths[@]}
  
    #make first header line in new map out file
    echo "filename,${newheader}" | sed -e 's/,/\t/g' >> ${mapout}
  
  fi

  # loop through every element in the array
  for (( i=0; i<${filepathsremainlength}; i++ ));
  do
    filepath=${filepathsremain[i]}
    interactiveWalkerSingle ${filepath} ${mapout} ${newheader} ${SSTOOLS_ROOT}
  done
}

function interactiveWalkerSingle() {

  filepath=$1
  mapout=$2
  newheader=$3
  SSTOOLS_ROOT=$4
  
  filename="$(basename ${filepath})"

  #source simple and special case
  source "${SSTOOLS_ROOT}/modules/bash-modules/simple-case-module.sh"
  source "${SSTOOLS_ROOT}/modules/bash-modules/special-case-module.sh"
  
  #declare new header names and order
  #newheader="CHR,BP,A1,Zscore,P"
  splitString="${SSTOOLS_ROOT}/modules/awk-modules/split-string-from-comma-to-whitespace.awk"
  newheadarray=($(echo ${newheader} | awk -f ${splitString} ))
  newarraylength=${#newheadarray[@]}
  
  
  
  #define awkscript
  awk_space_to_newline="${SSTOOLS_ROOT}/modules/awk-modules/split-string-from-whitespace-to-newline.awk"
  
  
  #initiate outrow string (end of each for loop append the colname)
  outrow="${filename}"
  echo "entering file ${filename}:"  >&2
  echo ""
  echo "printing head -n5 for file to get an overview" >&2
  zcat ${filepath} | head -n5 | column -t
  
  #loop over each column to be assigned
  oldheader=$(zcat ${filepath} | head -n1)
  oldheadarray=($(echo ${oldheader} | awk -f ${awk_space_to_newline} ))
  oldarraylength=${#oldheadarray[@]}
  
  echo "_________________________________________"
  
  for (( j=0; j<${newarraylength}; j++ ));
  do
    echo "what name is used for: ${newheadarray[j]} ?   (if nothing, hit enter)" >&2
    read col
  
    if [ -z "$col" ]
    then
      #if user just hit enter
      echo "entering special mode" >&2
      col2="$(special_case_interactive "${col}" "${newheadarray[j]}" "${oldheadarray[@]}")"
    else
      #if user actually wrote something (test and give one more chance if typed wrong)
      col2="$(simple_case_interactive "${col}" "${newheadarray[j]}" "${oldheadarray[@]}")"
    fi 
  
    echo "DONE We will use: ${col2}  -> Moving on to next colname" >&2
    echo ""
    #add to outfile string to be printed for all new header elements
    outrow="${outrow}&&&${col2}"
    
  done
  echo "printing row to outfile:" >&2
  echo ${outrow} | sed -e 's/&&&/\t/g' | tee -a >> ${mapout}
  #echo ${outrow} >> ${mapout}
  echo "#####################################" >&2
  echo "#This file is now finished" >&2
  echo "#####################################" >&2

  #return something
  echo "function is about to terminate" >&2
  echo "terminationMarkerInteraciveWalker"
  return 0
}

#checks
#1) That all studyIds have a file path
#2) All file paths actually lead to a file
