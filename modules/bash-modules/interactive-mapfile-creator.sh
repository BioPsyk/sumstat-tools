
function interactiveWalker() {

  metadata=$1
  rawfilesDir=$2
  mapout=$3
  newheader=$4
  SSTOOLS_ROOT=$5
  
  #metadata=${METADATA_GWAS}
  #rawfilesDir=${GWAS_SUMSTATS_FILE_DIR}
  #mapout=${MAPFILE_GWAS}
  
  #source simple and special case
  source "${SSTOOLS_ROOT}/modules/bash-modules/simple-case-module.sh"
  source "${SSTOOLS_ROOT}/modules/bash-modules/special-case-module.sh"
  source "${SSTOOLS_ROOT}/modules/bash-modules/studyid-which-remain.sh"
  
  #declare new header names and order
  #newheader="CHR,BP,A1,Zscore,P"
  splitString="${SSTOOLS_ROOT}/modules/awk-modules/split-string-from-comma-to-whitespace.awk"
  newheadarray=($(echo ${newheader} | awk -f ${splitString} ))
  newarraylength=${#newheadarray[@]}
  
  # Check if a mapfile with the same name already exists and if so quite.
  # This is to reassure that a file is not removed by mistake.
  # Therefore remove it manually. Rerunning this script can still take
  # a lot of effort as it is interactive.
  
  if [ -f ${mapout} ]; 
  then
    AWK_RETURN_MATCHING_ROWS="${SSTOOLS_ROOT}/modules/awk-modules/return-rows-which-match-pattern-in-array.awk"
    studyid=($(use_only_remaining_studyIds ${metadata} ${mapout}))
    #studyidstring="${studyid[@]}"
    studyidstring="$(IFS=,; echo "${studyid[*]}")"
    cat ${metadata} | awk -f ${AWK_RETURN_MATCHING_ROWS} -v idsX=${studyidstring} > tests/testresults/studyid-path-tmp.tmp
    #make sure same order therefore redefine studyid
    studyid=($(awk '{print $1}' tests/testresults/studyid-path-tmp.tmp))
    studyidlength=${#studyid[@]}
    filepaths=($(awk '{print $2}' tests/testresults/studyid-path-tmp.tmp))
    filepathslength=${#filepaths[@]}
  else
  
    #if maput does not exist we can safely use all avail study ids in meta data and create a new header
    studyid=($(cat ${metadata} | tail -n+2 | awk '{ print $1 }'))
    studyidlength=${#studyid[@]}
    filepaths=($(cat ${metadata} | tail -n+2 | awk '{ print $3 }'))
    filepathslength=${#filepaths[@]}
  
    #make first header line in new map out file
    echo "study_id,${newheader}" | sed -e 's/,/\t/g' >> ${mapout}
  
  fi
  
  #define awkscript
  awk_space_to_newline="${SSTOOLS_ROOT}/modules/awk-modules/split-string-from-whitespace-to-newline.awk"
  
  # loop through every element in the array
  for (( i=0; i<${studyidlength}; i++ ));
  do
  
    #initiate outrow string (end of each for loop append the colname)
    outrow="${studyid[i]}"
    echo "entering file ${i}:"  >&2
    echo ${studyid[i]}
    echo ${filepaths[i]}
    echo ""
    echo "printing head -n5 for file to get an overview" >&2
    zcat ${rawfilesDir}/${filepaths[i]} | head -n5 | column -t
  
    #loop over each column to be assigned
    oldheader=$(zcat ${rawfilesDir}/${filepaths[i]} | head -n1)
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
    echo "#This file is now finished, go to next" >&2
    echo "#####################################" >&2
  done

  #return something
  echo "function is about to terminate" >&2
  echo "terminationMarkerInteraciveWalker"
  return 0
}

#checks
#1) That all studyIds have a file path
#2) All file paths actually lead to a file
