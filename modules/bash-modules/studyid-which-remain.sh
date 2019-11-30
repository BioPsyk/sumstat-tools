function use_only_remaining_studyIds() {

  metadata=$1
  mapout=$2

  studyid=($(cat ${metadata} | tail -n+2 | awk '{ print $1 }'))
  studyidlength=${#studyid[@]}
  filepaths=($(cat ${metadata} | tail -n+2 | awk '{ print $3 }'))
  filepathslength=${#filepaths[@]}
  

  studyidlength=${#studyid[@]}
  studyid_mapout=($(cat ${mapout} | tail -n+2 | awk '{ print $1 }'))
  studyid_mapout_length=${#studyid_mapout[@]}
  echo "the mapout file exists and has already ${studyid_mapout_length} rows" >&2
  echo "do you want continue to work on the same file," >&2
  echo "not modifying existing rows [y] or not [n]?" >&2

  read yesorno

  echo "your answer is ${yesorno}" >&2

  if [ "${yesorno}" == "y" ];
  then

    studyid_remain=""
    file_remain=""
    studyid_notvisit=""
    for (( i=0; i<${studyidlength}; i++ ));
    do
      if [ $(contains "${studyid[i]}" "${studyid_mapout[@]}") == "n" ]; 
      then
        studyid_remain="${studyid_remain}${studyid[i]} "
        file_remain="${file_remain}${filepaths[i]} "
      else
        studyid_notvisit="${studyid_notvisit}${studyid[i]} "
      fi
    done

    studyid=(${studyid_remain})
    studyidlength=${#studyid[@]}
    filepaths=(${file_remain})
    filepathslength=${#filepaths[@]}
    studyidskip=(${studyid_notvisit})
    studyidskiplength=${#studyidskip[@]}



    echo "we will vist the remaining ${studyidlength} ids, skipping ${studyidskiplength}" >&2
    echo "${studyid[@]}"
    return 0

  else

    echo"The other alternative is to remove it manually and start over(if that is your intention)" >&2
    echo "exitmarker"
    return 1
  fi
  
}

