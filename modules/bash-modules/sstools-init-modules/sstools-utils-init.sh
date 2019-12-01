
#whatever the input make it array
paramarray=($@)

unset sstools_modifier location names beautify infile specialfunction successmapping

#set default outfile separator (infile is made as tab-sep)
separator="\t"

function general_usage(){
      echo "Usage:"
      echo "    sstools-gb ad-hoc -h                     Display help message for the 'ad-hoc' modifier"
      echo "    sstools-gb interactive -h                Display help message for the 'interactive' modifier"
}

# adhoc
function adhoc_usage(){
      echo "Usage:"
      echo "    sstools-gb ad-hoc -h                      (Display this help message)"
      echo " "

}
# adhocdo
function adhocdo_usage(){
      echo "Usage:"
      echo "    sstools-gb ad-hoc-do -h                      (Display this help message)"
      echo " "

}
# assemble
function asseble_usage(){
      echo "Usage:"
      echo "    sstools-gb assemble -h                      (Display this help message)"
      echo " "

}
function interactive_usage(){
      echo "Usage:"
      echo "    sstools-gb interactive -h                 (Display this help message)"
      echo " "
      echo " "
}
function nrow(){
      echo "Usage:"
      echo "    sstools-gb nrow -h                 (Display this help message)"
      echo " "
      echo " "
}


# check for and then remove first modifier from arguments list.
case "${paramarray[0]}" in
  ad-hoc)
    sstools_modifier=${paramarray[0]}
    getoptsstring=":hlnbs:"
    shift # Remove `install` from the argument list
    ;;
  ad-hoc-do)
    sstools_modifier=${paramarray[0]}
    getoptsstring=":hn:f:k:"
    shift # Remove `install` from the argument list
    ;;
  assemble)
    sstools_modifier=${paramarray[0]}
    getoptsstring=":hn:f:g:"
    shift # Remove `install` from the argument list
    ;;
  interactive)
    sstools_modifier=${paramarray[0]}
    getoptsstring=":hf:o:n:"
    shift # Remove `install` from the argument list
    ;;
  nrow)
    sstools_modifier=${paramarray[0]}
    getoptsstring=":hf:n:"
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
      if [ "$sstools_modifier" == "ad-hoc" ]; then
        adhoc_usage 1>&2
      elif [ "$sstools_modifier" == "ad-hoc" ]; then
        adhocdo_usage 1>&2
      elif [ "$sstools_modifier" == "assemble" ]; then
        assemble_usage 1>&2
      elif [ "$sstools_modifier" == "interactive" ]; then
        interactive_usage 1>&2
      elif [ "$sstools_modifier" == "nrow" ]; then
        nrow_usage 1>&2
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
      if [ "$sstools_modifier" == "ad-hoc" ]; then
        names=true
      elif [ "$sstools_modifier" == "ad-hoc-do" ]; then
        names="$OPTARG"
      elif [ "$sstools_modifier" == "assemble" ]; then
        names=true
      elif [ "$sstools_modifier" == "interactive" ]; then
        names="$OPTARG"
      elif [ "$sstools_modifier" == "nrow" ]; then
        names=true
      fi
      ;;
    b )
      beautify=true
      ;;
    g )
      successmapping="$OPTARG"
      ;;
    f )
      infile="$OPTARG"
      ;;
    k )
      specialfunction="$OPTARG"
      ;;
    o )
      outfile="$OPTARG"
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
    
    #show header names
    if [ $names ] ; then
      :
    else
      cmd1="${cmd1} | tail -n+2"
    fi
    
    #show a more readable output
    if [ $beautify ] ; then
      cmd1="${cmd1} | column -t"
    fi
  else
    echo "Error: not enough params are set"
    adhocdo_usage 1>&2 
    exit 1
  fi
elif [ "$sstools_modifier" == "ad-hoc-do" ] ; then
  if [ -n "$infile" ] && [ -n "$specialfunction" ]; then
    #where is the awk script stored
    cmd1="zcat ${infile} | gawk -f ${SSTOOLS_ADHOCDO_FUNCTIONS_ARRANGE} -v mapcols='${specialfunction}'"
    
    #which colnames to use in new output
    if [ -n "$names" ] ; then
      cmd1="${cmd1} -v newcols='${names}'"
    else
      cmd1="${cmd1} -v newcols='tmp' | tail -n+2"
    fi
  else
    echo "Error: not enough params are set"
    adhocdo_usage 1>&2 
    exit 1
  fi
elif [ "$sstools_modifier" == "assemble" ] ; then
  if [ -n "$infile" ] && [ -n "$successmapping" ] ; then

  cmd1="awk -v newheader='$((head -n1 ${successmapping} & gzip -dc ${infile} | head -n1) | awk -vRS='\n' -vORS='' 'NR==1{print $0"\t"}; NR==2{print $0"\n"}')' 'BEGIN{print newheader} NR==FNR{a[\$1]=\$0;next} FNR in a{print \$0, a[FNR]}' <(tail -n+2 ${successmapping}) <(gzip -dc ${infile} | tail -n+2)"

  else
    echo "Error: not enough params are set"
    adhocdo_usage 1>&2 
    exit 1
  fi
elif [ "$sstools_modifier" == "interactive" ] ; then
  if [ -n "$infile" ] && [ "$names" ] && [ "$outfile" ]; then
    cmd1="$infile $outfile $names"
  else
    echo "Error: not enough params are set"
    interactive_usage 1>&2 
    exit 1
  fi
elif [ "$sstools_modifier" == "nrow" ] ; then
  if [ -n "$infile" ] ; then
    cmd1=" cat $infile" 
    if [ -n "$names" ] ; then
      cmd1="${cmd1}"
    else
      cmd1="${cmd1} | tail -n+2"
    fi
    cmd1="${cmd1} | wc -l | awk '{print $1}'"
  else
    echo "Error: not enough params are set"
    interactive_usage 1>&2 
    exit 1
  fi
else
  echo "Error: not enough params are set"
  adhocdo_usage 1>&2 
  exit 1
fi


echo "$cmd1"
