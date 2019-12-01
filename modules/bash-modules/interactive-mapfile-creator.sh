function interactiveWalkerMultiple() {

  filepaths=$1
  mapout=$2
  newheader=$3
  SSTOOLS_ROOT=$4

  #splitString="${SSTOOLS_ROOT}/modules/awk-modules/split-string-from-comma-to-whitespace.awk"
  #filearray=($(echo ${filepaths} | awk -f ${splitString} ))
  #filearraylength=${#filearray[@]}

  #source "${SSTOOLS_ROOT}/modules/bash-modules/studyid-which-remain.sh"

  # Check if a mapfile with the same name already exists and if so quite.
  # This is to reassure that a file is not removed by mistake.
  # Therefore remove it manually. Rerunning this script can still take
  # a lot of effort as it is interactive.
  if [ -f ${mapout} ]; 
  then
    splitString="${SSTOOLS_ROOT}/modules/awk-modules/split-string-from-comma-to-whitespace.awk"
    newfilearray=($(echo ${filepaths} | awk -f ${splitString} ))
    newfilearraylength=${#newfilearray[@]}
    basenames="$(basename ${newfilearray[0]})"
    for (( i=1; i<${newfilearraylength}; i++ ));
    do
      basenames="${basenames},$(basename ${newfilearray[i]})" 
    done 

    filesalready=($(tail -n+2 ${mapout} | awk -vold=$basenames 'BEGIN{split(old,out,",")} {for(j=1; j <= length(out); j++){if ($1 == out[j]){print $1}}}'))
    #remove the one that already exists
    filepathsremain=($(for path in "${newfilearray[@]}"; do echo "${path}"; done | grep -v $filesalready))
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
