function filename_in_dir_from_index() {

  datadir=$1
  mapin=$2
  inx=$3
  names=$4

  #datadir="data/gwas-summary-stats"
  #mapin="out/mapping_information/mapfile-rsids-and-postitions.txt"
  #mapout="out/mapping_information/mapfile-genome-builds.txt"
  #inx=1

  if $names ; then
    :
  else
    inx2=$(( $inx + 1 ))
  fi

  cmd="awk 'FNR==${inx2}{print \$1}' ${mapin}"

  filename=$(eval ${cmd}) 
  fullpath="$(readlink -f ${datadir}/${filename})"
  echo "$fullpath"

}

function mapinfo_from_index() {
  mapin=$1
  inx=$2
  names=$3

  if $names ; then
    :
  else
    inx2=$(( $inx + 1 ))
  fi

  cmd="awk 'FNR==${inx2}{print \$2,\$3,\$4}' ${mapin}"

  mapinfo="$(eval ${cmd})"
  echo $mapinfo

}

function gbinfo_from_basenam() {
  mapin=$1
  basenam=$2
  names=$3

  if $names ; then
    :
  else
    inx2=$(( $inx + 1 ))
  fi

  cmd="awk '/^${basenam}/{print \$2}' ${mapin}"

  mapinfo="$(eval ${cmd})"
  echo $mapinfo
}

function wrap_lookup_prepare() {

  datadir=$1
  mapin=$2
  gbin=$3
  inx=$4

  infile_path=$(filename_in_dir_from_index $datadir $mapin $inx false)
  basenam=$(basename ${infile_path})
  mapinfo=$(mapinfo_from_index $mapin $inx false)
  gb=$(gbinfo_from_basenam $gbin $basenam false)

  #return all needed variables or run single 'which'  
  echo "${SSTOOLS_RLIB} ${mapinfo} ${infile_path} ${gb}" 
}

function wrap_assemble_prepare() {

  datadir=$1
  mapin=$2
  gbin=$3
  inx=$4

  #echo $datadir
  #echo $mapin
  #echo $gb
  #echo $inx
  
  infile_path=$(filename_in_dir_from_index $datadir $mapin $inx false)
  #mapinfo=$(mapinfo_from_index $mapin $inx false)
  #gb=$(gbinfo_from_index $gbin $inx false)


  #return all needed variables or run single 'which'  
  echo "${infile_path}" 

}

function wrap_which_prepare() {

  datadir=$1
  mapin=$2
  mapout=$3
  inx=$4

  infile_path=$(filename_in_dir_from_index $datadir $mapin $inx false)
  mapinfo=$(mapinfo_from_index $mapin $inx false)

  #return all needed variables or run single 'which'  
  echo "${SSTOOLS_RLIB} ${mapinfo} ${infile_path}" 

}



  

function ids_in_mapout() {
  mapin=$1
  mapout=$2
  invert=$3
  names=$4
  inxreturn=$5

  if $inxreturn ; then
    if $names ; then
      if $invert ; then
        cmd="awk 'NR==FNR{c[\$1]++;next}; {if (\$1 in c){}else{print FNR}}' $mapout $mapin"
      else
        cmd="awk 'NR==FNR{c[\$1]++;next}; {if (\$1 in c){print FNR}}' $mapout $mapin"
      fi
    else
      if $invert ; then
        cmd="awk 'NR==FNR && FNR>1{c[\$1]++;next}; FNR>1{if (\$1 in c){}else{print FNR-1}}' $mapout $mapin"
      else
        cmd="awk 'NR==FNR && FNR>1{c[\$1]++;next}; {if (\$1 in c){print FNR-1}}' $mapout $mapin"
      fi
    fi
  else
    if $names ; then
      if $invert ; then
        cmd="awk 'NR==FNR{c[\$1]++;next}; {if (\$1 in c){}else{print \$1}}' $mapout $mapin"
      else
        cmd="awk 'NR==FNR{c[\$1]++;next}; {if (\$1 in c){print \$1}}' $mapout $mapin"
      fi
    else
      if $invert ; then
        cmd="awk 'NR==FNR && FNR>1{c[\$1]++;next}; FNR>1{if (\$1 in c){}else{print \$1}}' $mapout $mapin"
      else
        cmd="awk 'NR==FNR && FNR>1{c[\$1]++;next}; {if (\$1 in c){print \$1}}' $mapout $mapin"
      fi
    fi
  fi
  eval $cmd
}

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

#echo "roligt/hej1,DIAG, hej3" | comma2newline | basename_stream | newline2symbol '|' | grep_from_mapfile $file $field $invert $names

function paths_in_map() {
  filepaths=$1
  mapout=$2
  inverse=$3
  #run all processing in a long pipe-maneuver
  echo "$filepaths" | comma2newline | grep "$(echo "$filepaths" | comma2newline | basename_stream | newline2symbol '|' | grep_from_mapfile $mapout 1 ${inverse} false | newline2symbol '|' )"
}


function dirpaths_in_map() {
  infile=$1
  mapout=$2
  inverse=$3
  filedir=$4
  #run all processing in a long pipe-maneuver
  ls ${filedir} | grep "$(cat ${infile} | awk '{print $1}' | basename_stream | newline2symbol '|' | grep_from_mapfile $mapout 1 ${inverse} false | newline2symbol '|' )"
}



function contains() {
    #store value in first position
    #and the rest in the following
    local arr=("$@")
	
    #check to see if anything is in the array
    #echo "array: ${arr[@]}"

    local arrlength=${#arr[@]}
    for (( i=1; i<${arrlength}; i++ )); do
        if [ "${arr[i]}" == "${arr[0]}" ]; then
            echo "y"
            return 0
        fi
    done
    echo "n"
    return 1
}
#contains "${col}" "${oldheadarray[@]}"

function simple_case_interactive() {
  colname=$1
  whatwewant=$2
  shift
  shift
  oharr=("$@")
  oharrlen=${#oldheadarray[@]}

  if [ $(contains "${colname}" "${oharr[@]}") == "n" ]; then
    echo "Warning! what you put in does not exist in file header. " >&2
    echo "Is there really an equivalent [y] or should we leave it blank [any key] " >&2
    read -n1 answer
    echo "" >&2
    if [ "${answer}" == "y" ]; then
       echo "ok you get one more chance to pick the right column for: ${whatwewant}" >&2
       read colname
 
       if [ $(contains "${colname}" "${oharr[@]}") == "y" ]
       then
         echo "Great it exists as a variable" >&2
         echo "${colname}"
         return 0
       else
         echo "Still cant be found, variable will be set to SKIP" >&2
         colname="---"
         echo "${colname}"
         return 0
       fi 
    fi 
 
  elif [ $(contains "${colname}" "${oharr[@]}") == "y" ]; then
    echo "${colname}"
    return 0
  else 
    #This should never happen as the function contains should return either y or n
    echo "Warning" >&2
    return 1
  fi
}
#simple_case_interactive "${col}" "${newheadarray[j]}" "${oldheadarray[@]}"

function special_case_interactive() {
  newheadcolname=${1}
  shift
  oharr=("$@")
  oharrlen=${#oharr[@]}

  #present list with available special functions
  echo "Which special function do you want to use to calculate ${newheadcolname}? Give number" >&2
  awk '{print $1, $3}' ${bash_special_functions} >&2
  read funcsel

  #change this to while larger loop, so we cant continue until the user gives a valid number
  availoptions=($(cat ${bash_special_functions} | tail -n+2 | awk '{print $1}' ))
  while [ $(contains "${funcsel}" "${availoptions[@]}") == "n" ]; do
    echo "Can't be right, not an option, try again:" >&2
    read funcsel
  done 

  echo "Alright, you picked the function" >&2
  func="$(tail -n+2 ${bash_special_functions} | awk -v input="${funcsel}" '{if($1 == input) print $3 }')"
  echo "${func}" >&2
  
  if [ ${funcsel} = "X" ]
  then
    echo "...the column for this file will be marked in case you want to exclude it later " >&2
    colreturn="---"
  else
    #here the user has picked a valid function, and we therefore have to figure out how many arguments it contains
    args="$(tail -n+2 ${bash_special_functions} | awk -v input="${funcsel}" 'NR==input{ print $4 }')"
    echo "It has ${args} arguments we have to find in the raw file header" >&2

    argsArray=($( cat ${bash_special_functions} | awk -v input="${funcsel}" 'BEGIN{input2=input+1}; NR==input2{sub(/^.*\(/,"",$3); sub(/\).*/,"",$3); split($3, out, ","); for(l=1; l <= length(out); l++){print out[l]} }'))
    #echo "${argsArray[0]}"
    #echo "${argsArray[1]}"

    funcname=($( cat ${bash_special_functions} | awk -v input="${funcsel}" 'BEGIN{input2=input+1}; NR==input2{sub(/\(.*/,"",$3); print $3 }'))

    argsArrayLength=${#argsArray[@]}
    for (( j=0; j<${argsArrayLength}; j++ ));
    do
      echo "what name is used for: ${argsArray[j]}" ? >&2
      echo "Available field names: ${oharr[@]}" >&2
      read col

      if [ -z "$col" ]
      then
        echo "you have to put a value, one more try, give now correct, otherwise '---' is returned: " >&2
        read col
        if [ -z "$col" ]
        then
           colname="---"
        else
          #For each single column, same as simple mode
          colname="$(simple_case_interactive "${col}" "${argsArray[j]}" "${oharr[@]}")"
        fi
      else
        #For each single column, same as simple mode
        colname="$(simple_case_interactive "${col}" "${argsArray[j]}" "${oharr[@]}")"
      fi
      #If all seems fine (taken care of by the simple_case_interactive function), Store output 
      if [ "${j}" == "0" ]
      then
        colreturn="${funcname}(${colname}"
      else
        colreturn="${colreturn},${colname}"
      fi
    done
  fi
  # %? is to remove the trailing comma..
  #colreturn=${colreturn%?}

  if [ ${colreturn} = "---" ]
  then
    echo "${colreturn}"
    return 0
  else
    # add final parenthesis
    echo "${colreturn})"
    return 0
  fi
}

#TODO: for some reason the variable to be created is the frist colname presented when the 
#      available colnames are presented. This can lead to confusion.

function interactiveWalkerMultiple() {

  filepaths=$1
  mapout=$2
  newheader=$3
  SSTOOLS_ROOT=$4

  if [ -f ${mapout} ]; 
  then
    filepathsremain=($(paths_in_map $filepaths $mapout true))
    filepathsremainlength=${#filepathsremain[@]}
  else
    #if maput does not exist we can safely use all avail filenames
    filepathsremain=($(echo "$filepaths" | comma2newline))
    filepathsremainlength=${#filepaths[@]}
  
    #make first header line in new map out file
    echo "filename,${newheader}" | sed -e 's/,/\t/g' >> ${mapout}
  
  fi

  # loop through every element in the array
  for (( i=0; i<${filepathsremainlength}; i++ ));
  do
    echo "iterating through file ${i} of ${filepathsremainlength}" 2>&1
    filepath=${filepathsremain[${i}]}
    echo "now treating file ${filepath}" 2>&1
    interactiveWalkerSingle ${filepath} ${mapout} ${newheader} ${SSTOOLS_ROOT}
  done
}

function interactiveWalkerSingle() {

  filepath=$1
  mapout=$2
  newheader=$3
  SSTOOLS_ROOT=$4
  
  filename="$(basename ${filepath})"

  #source simple and special case (these aren now sourced or included from elsewhere)
  #source "${SSTOOLS_ROOT}/modules/bash-modules/simple-case-module.sh"
  #source "${SSTOOLS_ROOT}/modules/bash-modules/special-case-module.sh"
  
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


#function paths_not_on_map() {
#  filepaths=$1
#  mapout=$2
#  #get mapfile names
#  regformat="$(echo "$filepaths" | comma2newline | basename_stream | newline2symbol '|' )"
#  #filenamessalready=($(echo "$regformat" | grep_from_mapfile $mapout 1 FALSE FALSE))
#  filenamesremain=($(echo "$regformat" | grep_from_mapfile $mapout 1 TRUE FALSE))
#
#  #get full path
#  regformat2="$(for line in "${filenamesremain[@]}"; do echo $line | newline2symbol '|' )"
#  echo "$filepaths" | comma2newline | grep $regformat2
#}
#
