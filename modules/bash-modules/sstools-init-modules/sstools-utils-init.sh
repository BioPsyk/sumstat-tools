
#whatever the input make it array
paramarray=($@)

unset sstools_modifier location names beautify infile specialfunction successmapping indir mapfile log outdir inx 

#set default outfile separator (infile is made as tab-sep)
separator="\t"

function general_usage(){
      echo "Usage:"
      echo "    sstools-utils ad-hoc -h                     Display help message for the 'ad-hoc' modifier"
      echo "    sstools-utils interactive -h                Display help message for the 'interactive' modifier"
}

# adhoc
function adhoc_usage(){
      echo "Usage:"
      echo "    sstools-utils ad-hoc -h                      (Display this help message)"
      echo " "

}
# adhocdo
function adhocdo_usage(){
      echo "Usage:"
      echo "    sstools-utils ad-hoc-do -h                      (Display this help message)"
      echo " "

}
# assemble
function assemble_usage(){
      echo "Usage:"
      echo "    sstools-utils assemble -h                      (Display this help message)"
      echo " "

}
function assemblewrap_usage(){
      echo "Usage:"
      echo "    sstools-utils assemble-wrap -h                      (Display this help message)"
      echo " "

}
function interactive_usage(){
      echo "Usage:"
      echo "    sstools-utils interactive -h                 (Display this help message)"
      echo " "
      echo " "
}
function nrow(){
      echo "Usage:"
      echo "    sstools-utils nrow -h                 (Display this help message)"
      echo " "
      echo " "
}
function file-in-map(){
      echo "Usage:"
      echo "    sstools-utils file-in-map -h                 (Display this help message)"
      echo " "
      echo " "
}


# check for and then remove first modifier from arguments list.
case "${paramarray[0]}" in
  ad-hoc)
    sstools_modifier=${paramarray[0]}
    getoptsstring=":hlns:"
    shift # Remove `install` from the argument list
    ;;
  ad-hoc-do)
    sstools_modifier=${paramarray[0]}
    getoptsstring=":hn:f:k:"
    shift # Remove `install` from the argument list
    ;;
  assemble)
    sstools_modifier=${paramarray[0]}
    getoptsstring=":hn:f:g:c:"
    shift # Remove `install` from the argument list
    ;;
  assemble-wrap)
    sstools_modifier=${paramarray[0]}
    getoptsstring=":hg:d:m:o:i:"
    shift # Remove `install` from the argument list
    ;;
  interactive)
    sstools_modifier=${paramarray[0]}
    getoptsstring=":hf:o:n:"
    shift # Remove `install` from the argument list
    ;;
  nrow)
    sstools_modifier=${paramarray[0]}
    getoptsstring=":hf:n"
    shift # Remove `install` from the argument list
    ;;
  file-in-map)
    sstools_modifier=${paramarray[0]}
    getoptsstring=":hf:p:o:d:"
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
      if [ "$sstools_modifier" == "ad-hoc" ]; then
        adhoc_usage 1>&2
      elif [ "$sstools_modifier" == "ad-hoc-do" ]; then
        adhocdo_usage 1>&2
      elif [ "$sstools_modifier" == "assemble" ]; then
        assemble_usage 1>&2
      elif [ "$sstools_modifier" == "assemble-wrap" ]; then
        assemblewrap_usage 1>&2
      elif [ "$sstools_modifier" == "interactive" ]; then
        interactive_usage 1>&2
      elif [ "$sstools_modifier" == "nrow" ]; then
        nrow_usage 1>&2
      elif [ "$sstools_modifier" == "file-in-map" ]; then
        fileinmap_usage 1>&2
      fi
      exit 0
      ;;
    l )
      if [ "$sstools_modifier" == "assemble-wrap" ]; then
        log="$OPTARG"
      else
        location=true
      fi
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
    c )
      selcols="$OPTARG"
      ;;
    m )
      mapfile="$OPTARG"
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
    p )
      paths="$OPTARG"
      ;;
    o )
      if [ "$sstools_modifier" == "assemble-wrap" ]; then
        outdir="$OPTARG"
      else
        outfile="$OPTARG"
      fi 
      ;;
    d )
      indir="$OPTARG"
      ;;
    i )
      if [ "$sstools_modifier" == "assemble-wrap" ]; then
        inx="$OPTARG"
      else
        inverse="$OPTARG"
      fi
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
    echo "${cmd1}"
  else
    echo "Error: not enough params are set"
    adhocdo_usage 1>&2 
    exit 1
  fi
elif [ "$sstools_modifier" == "ad-hoc-do" ] ; then
  if [ -n "$specialfunction" ]; then

    if [ -n "$infile" ] ; then
    :
    else 
      infile="-"
    fi

    #which colnames to use in new output
    if [ -n "$names" ] ; then
      newcols="${names}"
    else
      #reuse mapcols as outcols      
      newcols_nocomma=${specialfunction//,|/}
      newcols=${newcols_nocomma//\|/,}
    fi
   
    echo "${infile} ${SSTOOLS_ADHOCDO_FUNCTIONS_ARRANGE} ${specialfunction} ${newcols}"

  else
    echo "Error: not enough params are set"
    adhocdo_usage 1>&2 
    exit 1
  fi
elif [ "$sstools_modifier" == "assemble" ] ; then
  if [ -n "$successmapping" ] ; then

    if [ -n "$infile" ] ; then
    :
    else 
      infile="-"
    fi
    #cmd1="awk -v newheader='$((head -n1 ${successmapping} & gzip -dc ${infile} | head -n1) | awk -vRS='\n' -vORS='' 'NR==1{print $0"\t"}; NR==2{print $0"\n"}')' 'BEGIN{print newheader} NR==FNR{a[\$1]=\$0;next} FNR in a{print \$0, a[FNR]}' <(tail -n+2 ${successmapping}) <(gzip -dc ${infile} | tail -n+2)"
    echo "${infile} ${successmapping}"
  else
    echo "Error: not enough params are set"
    assemble_usage 1>&2 
    exit 1
  fi
elif [ "$sstools_modifier" == "assemble-wrap" ] ; then
  if [ -n "$indir" ] && [ -n "$mapfile" ] &&  [ -n "$successmapping" ] && [ -n "$outdir" ] && [ -n "$inx" ] && [ -n "$log" ] ; then
    #log file stuff not implemented yet
    cmd1="${indir} ${mapfile} ${successmapping} ${inx} ${outdir} ${log}"
    echo "${cmd1}"
  elif [ -n "$indir" ] && [ -n "$mapfile" ] &&  [ -n "$successmapping" ] && [ -n "$outdir" ] && [ -n "$inx" ] ; then
    cmd1="${indir} ${mapfile} ${successmapping} ${inx} ${outdir}"
    echo "${cmd1}"
  else
    echo "Error: not enough params are set"
    assemblewrap_usage 1>&2 
    exit 1
  fi
elif [ "$sstools_modifier" == "interactive" ] ; then
  if [ -n "$infile" ] && [ "$names" ] && [ "$outfile" ]; then
    cmd1="$infile $outfile $names"
    echo "${cmd1}"
  else
    echo "Error: not enough params are set"
    interactive_usage 1>&2 
    exit 1
  fi
elif [ "$sstools_modifier" == "nrow" ] ; then
  if [ -n "$infile" ] ; then
    cmd1=" cat $infile" 
    if [ "$names" ] ; then
      cmd1="${cmd1}"
    else
      cmd1="${cmd1} | tail -n+2"
    fi
    cmd1="${cmd1} | wc -l | awk '{print $1}'"
    echo "${cmd1}"
  else
    echo "Error: not enough params are set"
    nrow_usage 1>&2 
    exit 1
  fi
elif [ "$sstools_modifier" == "file-in-map" ] ; then
  if [ -n "$paths" ] && [ -n "$outfile" ]; then
      cmd1="function paths_in_map $paths" $infile "$inverse"
    echo "${cmd1}"
  elif [ -n "$infile" ] && [ -n "$outfile" ] && [ -n "$indir" ]; then
      cmd1="function entries_in_map $infile" $outfile "$inverse" $indir
    echo "${cmd1}"
  else
    echo "Error: not enough params are set"
    idexists_usage 1>&2 
    exit 1
  fi
else
  echo "Error: not enough params are set"
  adhocdo_usage 1>&2 
  exit 1
fi

