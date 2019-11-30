#!/usr/bin/bash 

DIR=$1
AWK_CHECK_NUMBER_OF_FIELDS="modules/awk-modules/check-if-number-of-fields-are-same-for-all-rows.awk"
AWK_SUMMARY_OF_FIELD_CHECK="modules/awk-modules/summarize-bad-and-good-file-field-checks.awk"

#remove outfile, if exists
rm -f tests/testresults/tmp-field-check.tmp

for file in ${DIR}/*gz ; do
  printf "%s\n" "running ${file}"
  zcat ${file} | awk -f ${AWK_CHECK_NUMBER_OF_FIELDS} -v filename=${file} >> tests/testresults/tmp-field-check.tmp 
done

#summary stats
cat tests/testresults/tmp-field-check.tmp | awk -f ${AWK_SUMMARY_OF_FIELD_CHECK}

#bad files were
grep "bad" tests/testresults/tmp-field-check.tmp

#remove tmp file
rm tests/testresults/tmp-field-check.tmp

