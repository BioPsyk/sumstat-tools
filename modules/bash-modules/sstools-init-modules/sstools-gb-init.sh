
#whatever the input make it array
paramarray=($@)

unset sstools_modifier R_library chr_field_name bp_field_name rs_field_name infile_path genome_build output_dir

function general_usage(){
      echo "Usage:"
      echo "    sstools-gb which -h                      Display help message for the 'which' modifier"
      echo "    sstools-gb lookup -h                     Display help message for the 'lookup' modifier"
}

# which_usage
function which_usage(){
      echo "Usage:"
      echo "    sstools-gb which -h                      (Display this help message)"
      echo " "
      echo "Required params:"
      echo "    sstools-gb which -c CHR -p POS -f INFILE"
      echo " "
      echo "Optional params:"
      echo "    sstools-gb which -l LIBLOCATION -r RSID"
      echo " "
}
function lookup_usage(){
      echo "Usage:"
      echo "    sstools-gb lookup -h                      (Display this help message)"
      echo " "
      echo "Required params:"
      echo "    sstools-gb lookup [-c CHR -p POS &| -r RSID] -g GENOME_BUILD -f INFILE -o OUTDIR"
      echo " "
      echo "Optional params:"
      echo "    sstools-gb lookup -l LIBLOCATION"
      echo " "
}

# check for and then remove first modifier from arguments list.
case "${paramarray[0]}" in
  which)
    sstools_modifier=${paramarray[0]}
    shift # Remove `install` from the argument list
    ;;
  lookup)
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
while getopts ":hc:p:r:f:l:g:o:" opt "${paramarray[@]}"; do
  case ${opt} in
    h )
      if [ "$sstools_modifier" == "which" ]; then
        which_usage 1>&2
      elif [ "$sstools_modifier" == "lookup" ]; then
        lookup_usage 1>&2
      fi
      exit 0
      ;;
    c )
      chr_field_name=$OPTARG
      ;;
    p )
      bp_field_name=$OPTARG
      ;;
    r )
      rs_field_name=$OPTARG
      ;;
    f )
      infile_path=$OPTARG
      ;;
    g )
      genome_build=$OPTARG
      ;;
    l )
      #if not set, a default is already set in config file (user or main)
      SSTOOLS_RLIB=$OPTARG
      ;;
    o )
      #if not set, a default is already set in config file (user or main)
      output_dir=$OPTARG
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
if [ "$sstools_modifier" == "which" ] ; then
  if [ -n "$infile_path" ] ; then
    if [ -n "$chr_field_name" ] && [ -n "$bp_field_name" ] && [ -n "$rs_field_name" ] ; then
      toreturn="${SSTOOLS_RLIB} ${chr_field_name} ${bp_field_name} "$rs_field_name" ${infile_path}"
    elif [ -n "$infile_path" ] && [ -n "$chr_field_name" ] && [ -n "$bp_field_name" ] ; then
      toreturn="${SSTOOLS_RLIB} ${chr_field_name} ${bp_field_name} --- ${infile_path}"
    elif [ -n "$infile_path" ] && [ -n "$rs_field_name" ] ; then
      toreturn="${SSTOOLS_RLIB} --- --- ${rs_field_name} ${infile_path}"
    else
      echo "Error: all required params have to be set"
      which_usage 1>&2 
      exit 1
    fi 
  else
    echo "Error: all required params have to be set, infile missing"
    which_usage 1>&2 
    exit 1
fi
elif [ "$sstools_modifier" == "lookup" ]; then
  if [ -n "$infile_path" ] && [ -n "$genome_build" ] && [ -n "$output_dir" ] ; then
    if [ -n "$chr_field_name" ] && [ -n "$bp_field_name" ] && [ -n "$rs_field_name" ] ; then
      toreturn="${SSTOOLS_RLIB} ${chr_field_name} ${bp_field_name} $rs_field_name ${infile_path} ${genome_build} ${output_dir}"
    elif [ -n "$chr_field_name" ] && [ -n "$bp_field_name" ] ; then
      toreturn="${SSTOOLS_RLIB} ${chr_field_name} ${bp_field_name} --- ${infile_path} ${genome_build} ${output_dir}"
    elif [ -n "$rs_field_name" ] ; then
      toreturn="${SSTOOLS_RLIB} --- --- ${rs_field_name} ${infile_path} ${genome_build} ${output_dir}"
    else
      echo "Error: all required params have to be set"
      lookup_usage 1>&2
      exit 1
    fi 
  else
    echo "Error: all required params have to be set"
    lookup_usage 1>&2
    exit 1
  fi
else
  echo "Error: a modifier has to be set"
  general_usage 1>&2
  exit 1
fi

#return all set arguments
echo "${toreturn}"

