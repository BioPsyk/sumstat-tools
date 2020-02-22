
#whatever the input make it array
paramarray=($@)

unset sstools_modifier infile 

#set default outfile separator (infile is made as tab-sep)
separator="\t"

function general_usage(){
      echo "Usage:"
      echo "    sstools-eallele modifier -h                     Display help message for the 'modifier' modifier"
}

# adhoc
function modifier_usage(){
      echo "Usage:"
      echo "    sstools-eallele modifier -h                      (Display this help message)"
      echo " "

}
function correction_usage(){
      echo "Usage:"
      echo "    sstools-eallele correction -h                      (Display this help message)"
      echo " "

}

# check for and then remove first modifier from arguments list.
case "${paramarray[0]}" in
  modifier)
    sstools_modifier=${paramarray[0]}
    getoptsstring=":hf:k:"
    shift # Remove `install` from the argument list
    ;;
  correction)
    sstools_modifier=${paramarray[0]}
    getoptsstring=":hf:a"
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

#set default params
separator="\t"

# starting getops with :, puts the checking in silent mode for errors.
while getopts "${getoptsstring}" opt "${paramarray[@]}"; do
  case ${opt} in
    h )
      if [ "$sstools_modifier" == "modifier" ]; then
        modifier_usage 1>&2
      elif [ "$sstools_modifier" == "placeholder" ]; then
        placeholder_usage 1>&2
      fi
      exit 0
      ;;
    f )
        infile="$OPTARG"
      ;;
    k )
        rinx="$OPTARG"
      ;;
    a )
        allele2_missing=true
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
if [ "$sstools_modifier" == "modifier" ] ; then
  if [ $rinx ] ; then
    if [ -n "$infile" ] ; then
    :
    else 
      infile="-"
    fi
    echo "${infile} ${rinx}"
  else
    echo "Error: not enough params are set"
    adhocdo_usage 1>&2 
    exit 1
  fi
elif [ "$sstools_modifier" == "correction" ] ; then
  if [ -n "$infile" ] && [ "$allele2_missing" = true ]; then
    echo "${infile}" "${SSTOOLS_AWK_EALLELE_CORRECTION_A1}"
    #echo "${infile} ${SSTOOLS_AWK_EALLELE_CORRECTION_A1}" 1>&2

  elif [ -n "$infile" ]; then

    echo "${infile}" "${SSTOOLS_AWK_EALLELE_CORRECTION_A1A2}"
    #echo "${infile} ${SSTOOLS_AWK_EALLELE_CORRECTION_A1A2}" 1>&2
  else
    echo "Error: not enough params are set"
    adhocdo_usage 1>&2 
    exit 1
  fi
else
  echo "Error: not enough params are set"
  adhocdo_usage 1>&2 
  exit 1
fi

