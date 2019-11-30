#awk_special_functions="modules/awk-modules/special-column-merge-split-alter-functions.awk"
bash_special_functions="modules/bash-modules/special-function-desc-file.txt"

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
