#echo "$@" 1>&2
#echo "$0" 1>&2
#echo "$1" 1>&2
#echo "$2" 1>&2
#echo "|$3||" 1>&2
#echo "$4" 1>&2
#echo "----" 1>&2


unset sstools_modifier infile_path output_dir input_dir output_file tabsep whitespace

function general_usage(){
      echo "Usage:"
      echo "    sstools-raw tab-sep -h                      Display help message for the 'tab-sep' modifier"
}

# which_usage
function tabsep_usage(){
      echo "Usage:"
      echo "    sstools-gb tab-sep -h                      (Display this help message)"
      echo " "
}
function newheader_usage(){
      echo "Usage:"
      echo "    sstools-gb new-header -h                      (Display this help message)"
      echo " "
}
function whatsep_usage(){
      echo "Usage:"
      echo "    sstools-gb what-sep -h                      (Display this help message)"
      echo " "
}
function newsep_usage(){
      echo "Usage:"
      echo "    sstools-gb new-sep -h                      (Display this help message)"
      echo " "
}

# check for and then remove first modifier from arguments list.
case "${1}" in
  tab-sep)
    sstools_modifier=${1}
    getoptsstring=":hd:f:"
    shift 
    ;;
  new-header)
    sstools_modifier=${1}
    getoptsstring=":hf:c:"
    shift 
    ;;
  what-sep)
    sstools_modifier=${1}
    getoptsstring=":hf:"
    shift 
    ;;
  new-sep)
    sstools_modifier=${1}
    getoptsstring=":hf:t:w:"
    shift 
    ;;
  *)
    echo "you have to specify a modifier, see below for example"
    general_usage 1>&2
    exit 1
    ;;
esac

# starting getops with :, puts the checking in silent mode for errors.
while getopts "${getoptsstring}" opt "$@"; do
  case ${opt} in
    h )
      if [ "$sstools_modifier" == "tab-sep" ]; then
        tabsep_usage 1>&2
      fi
      if [ "$sstools_modifier" == "new-sep" ]; then
        newsep_usage 1>&2
      fi
      exit 0
      ;;
    f )
      infile_path=$OPTARG
      ;;
    t )
      tabsep=$OPTARG
      ;;
    w )
      whitespace=$OPTARG
      ;;
    c )
      colnames=$OPTARG
      ;;
    o )
      output_file=$OPTARG
      ;;
    d )
      input_dir=$OPTARG
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
if [ "$sstools_modifier" == "tab-sep" ] ; then
  if [ -n "$input_dir" ] ; then
    toreturn="${input_dir}"
    printf "%s\n" "${input_dir}"  
  else
    echo "Error: all required params have to be set, input dir missing"
    tab-sep_usage 1>&2 
    exit 1
  echo "${toreturn}"
  fi
elif [ "$sstools_modifier" == "new-header" ] ; then
  if [ -n "$infile_path" ] ; then
  :
  else 
    infile_path="-"
  fi
  if [ -n "$infile_path" ] && [ -n "$colnames" ] ; then
    printf "%s¬%s\n" ${infile_path} ${colnames}  
  else
    echo "Error: all required params have to be set, input file missing"
    newheader_usage 1>&2 
    exit 1
  echo "${toreturn}"
  fi
elif [ "$sstools_modifier" == "what-sep" ] ; then
  if [ -n "$infile_path" ] ; then
  :
  else 
    infile_path="-"
  fi
  tabsep="=TAB="
  whitespace="_"
  if [ -n "$infile_path" ] && [ -n "$tabsep" ] && [ -n "$whitespace" ]; then
    printf "%s¬%s¬%s\n" "${infile_path} ${tabsep} ${whitespace}"  
  else
    echo "Error: all required params have to be set, input file missing"
    whatsep_usage 1>&2 
    exit 1
  fi
elif [ "$sstools_modifier" == "new-sep" ] ; then
  if [ -n "$infile_path" ] ; then
  :
  else 
    infile_path="-"
  fi
  tabsep=""
  if [[ -n "${tabsep}" || -z "${tabsep}" ]] ; then
  :
  else 
    tabsep=""
  fi
  if [ -n "$whitespace" ] ; then
  :
  else 
    whitespace=""
  fi
  if [ -n "$infile_path" ] && [[ -n "${tabsep}" || -z "${tabsep}" ]] && [[ -n "${whitespace}" || -z "${whitespace}" ]]; then
    #printf "%s¬%s¬%s\n" "${infile_path}" "${tabsep}" "${whitespace}"  1>&2
    printf "%s¬%s¬%s\n" "${infile_path}" "${tabsep}" "${whitespace}"
  else
    echo "Error: all required params have to be set"
    whatsep_usage 1>&2 
    exit 1
  fi
else
  echo "Error: a modifier has to be set"
  general_usage 1>&2
  exit 1
fi

