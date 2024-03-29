
#whatever the input make it array
paramarray=($@)

unset sstools_modifier R_library chr_field_name bp_field_name rs_field_name infile_path genome_build output_dir input_dir mapfile inx output_file

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
function whichwrap_usage(){
      echo "Usage:"
      echo "    sstools-gb which-wrap -h                      (Display this help message)"
      echo " "
}
function whichexists(){
      echo "Usage:"
      echo "    sstools-gb which-exists -h                      (Display this help message)"
      echo " "
}
function liftover_usage(){
      echo "Usage:"
      echo "    sstools-gb liftover -h                      (Display this help message)"
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
function lookupwrap_usage(){
      echo "Usage:"
      echo "    sstools-gb lookup-wrap -h                      (Display this help message)"
      echo " "
}

# check for and then remove first modifier from arguments list.
case "${paramarray[0]}" in
  which)
    sstools_modifier=${paramarray[0]}
    getoptsstring=":hc:p:r:f:g:"
    shift # Remove `install` from the argument list
    ;;
  which-wrap)
    sstools_modifier=${paramarray[0]}
    getoptsstring=":ho:d:m:i:"
    shift # Remove `install` from the argument list
    ;;
  which-exists)
    sstools_modifier=${paramarray[0]}
    getoptsstring=":hm:g:ikn"
    shift # Remove `install` from the argument list
    ;;
  liftover)
    sstools_modifier=${paramarray[0]}
    getoptsstring=":hf:g:q:s:i:"
    shift # Remove `install` from the argument list
    ;;
  lookup)
    sstools_modifier=${paramarray[0]}
    getoptsstring=":hc:p:r:f:g:o:"
    shift # Remove `install` from the argument list
    ;;
  lookup-wrap)
    sstools_modifier=${paramarray[0]}
    getoptsstring=":ho:d:m:g:i:l:"
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
while getopts "${getoptsstring}" opt "${paramarray[@]}"; do
  case ${opt} in
    h )
      if [ "$sstools_modifier" == "which" ]; then
        which_usage 1>&2
      elif [ "$sstools_modifier" == "which-wrap" ]; then
        whichwrap_usage 1>&2
      elif [ "$sstools_modifier" == "which-exists" ]; then
        whichexists_usage 1>&2
      elif [ "$sstools_modifier" == "lookup" ]; then
        lookup_usage 1>&2
      elif [ "$sstools_modifier" == "liftover" ]; then
        liftover_usage 1>&2
      elif [ "$sstools_modifier" == "lookup-wrap" ]; then
        lookupwrap_usage 1>&2
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
      log=$OPTARG
      ;;
    o )
      if [ "$sstools_modifier" == "which" ]; then
        output_file=$OPTARG
      elif [ "$sstools_modifier" == "which-wrap" ]; then
        output_file=$OPTARG
      elif [ "$sstools_modifier" == "lookup" ]; then
        output_dir=$OPTARG
      elif [ "$sstools_modifier" == "lookup-wrap" ]; then
        output_dir=$OPTARG
      fi
      ;;
    d )
      input_dir=$OPTARG
      ;;
    m )
      mapfile=$OPTARG
      ;;
    i )
      if [ "$sstools_modifier" == "which-exists" ]; then
        inx=true
      else
      inx=$OPTARG
      fi
      ;;
    k )
      invert=true
      ;;
    n )
      names=true
      ;;
    q )
      gbout=$OPTARG
      ;;
    s )
      size=$OPTARG
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
elif [ "$sstools_modifier" == "which-wrap" ]; then
  if [ -n "$input_dir" ] &&  [ -n "$mapfile" ] &&  [ -n "$output_file" ] && [ -n "$inx" ] ; then
    toreturn="${input_dir} ${mapfile} ${output_file} ${inx}"
  else
    echo "Error: all required params have to be set, infile missing"
    which_usage 1>&2 
    exit 1
  fi
elif [ "$sstools_modifier" == "which-exists" ] ; then
  if [ -n "$genome_build" ] &&  [ -n "$mapfile" ] ; then
    if [ -n "$invert" ] ; then
      :
    else
      invert=false
    fi
    if [ -n "$inx" ] ; then
      :
    else
      inx=false
    fi
    if [ -n "$names" ] ; then
      :
    else
      names=false
    fi
    toreturn="${mapfile} ${genome_build} ${invert} ${names} ${inx}"
  else
    echo "Error: all required params have to be set, infile missing"
    which_usage 1>&2 
    exit 1
  fi
elif [ "$sstools_modifier" == "liftover" ]; then
      #will write check for these arguments below later
      #echo "${infile_path} ${SSTOOLS_RLIB} ${genome_build} ${gbout} ${size} ${inx}" 1>&2
      toreturn="${infile_path} ${SSTOOLS_RLIB} ${genome_build} ${gbout} ${size} ${inx}"
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
elif [ "$sstools_modifier" == "lookup-wrap" ]; then
  if [ -n "$input_dir" ] && [ -n "$mapfile" ] &&  [ -n "$genome_build" ] && [ -n "$output_dir" ] && [ -n "$inx" ] && [ -n "$log" ] ; then
    toreturn="${input_dir} ${mapfile} ${genome_build} ${inx} ${output_dir} ${log}"
  else
    echo "Error: all required params have to be set, infile missing"
    lookupwrap_usage 1>&2 
    exit 1
  fi
else
  echo "Error: a modifier has to be set"
  general_usage 1>&2
  exit 1
fi

#return all set arguments
echo "${toreturn}"

