
#whatever the input make it array
paramarray=($@)

unset sstools_modifier location names beautify

#set default outfile separator (infile is made as tab-sep)
separator="\t"

function general_usage(){
      echo "Usage:"
      echo "    sstools-gb ad-hoc -h                     Display help message for the 'ad-hoc' modifier"
      echo "    sstools-gb interactive -h                Display help message for the 'interactive' modifier"
}

# which_usage
function adhoc_usage(){
      echo "Usage:"
      echo "    sstools-gb ad-hoc -h                      (Display this help message)"
      echo " "

}
function interactive_usage(){
      echo "Usage:"
      echo "    sstools-gb interactive -h                 (Display this help message)"
      echo " "
      echo " "
}

# check for and then remove first modifier from arguments list.
case "${paramarray[0]}" in
  ad-hoc)
    sstools_modifier=${paramarray[0]}
    shift # Remove `install` from the argument list
    ;;
  interactive)
    sstools_modifier=${paramarray[0]}
    shift # Remove `install` from the argument list
    ;;
  *)
    echo "you have to specify a modifier, see below for example"
    general_usage 1>&2
    exit 1
    ;;
esac

# remove modifier, 1st element
paramarray=("${paramarray[@]:1}")

# starting getops with :, puts the checking in silent mode for errors.
while getopts ":hlnbs:" opt "${paramarray[@]}"; do
  case ${opt} in
    h )
      if [ "$sstools_modifier" == "ad-hoc" ]; then
        adhoc_usage 1>&2
      elif [ "$sstools_modifier" == "interactive" ]; then
        interactive_usage 1>&2
      fi
      exit 0
      ;;
    l )
      location=true
      ;;
    s )
      separator="$OPTARG"
      ;;
    n )
      names=true
      ;;
    b )
      beautify=true
      ;;
    \? )
      echo "Invalid Option: -$OPTARG" 1>&2
      exit 1
      ;;
    : )
      echo "Invalid Option: -$OPTARG requires an argument" 1>&2
      exit 1
      ;;
  esac
done

# check that all required arguments for the selected modifier is set
if [ "$sstools_modifier" == "ad-hoc" ] ; then
  if [ $location ] ; then
    #where are the special functions for locations stored
    cmd1="cat ${SSTOOLS_ADHOC_FUNCTIONS_LOCATION}"

    #use out file separator
    cmd1="${cmd1} | awk -vOFS='${separator}' '{print \$1, \$2, \$3, \$4}'"

    if [ $names ] ; then
      :
    else
      cmd1="${cmd1} | tail -n+2"
    fi
    if [ $beautify ] ; then
      cmd1="${cmd1} | column -t"
    fi
  fi

else
  echo "Error: no params are set"
  adhoc_usage 1>&2 
  exit 1
fi

## The interactive code part
#if [ "$sstools_modifier" == "interactive" ]; then
#  
#  echo "This code has to be written"
#
#else
#  echo "Error: a modifier has to be set"
#  general_usage 1>&2
#  exit 1
#fi

echo "$cmd1"
