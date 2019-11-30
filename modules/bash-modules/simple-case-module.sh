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

