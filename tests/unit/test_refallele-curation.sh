#!/usr/bin/env bash

set -euo pipefail

test_script="refallele-curation"
initial_dir=$(pwd)"/${test_script}"
curr_case=""

awk_f1="${PROJECT_DIR}/modules/awk-modules/refallele-curation.awk"
awk_f2="${PROJECT_DIR}/modules/awk-modules/awk-helper-functions/allele-curation-helpers.awk"

mkdir "${initial_dir}"
cd "${initial_dir}"

#=================================================================================
# Helpers
#=================================================================================

function _setup {
  mkdir "${1}"
  cd "${1}"
  curr_case="${1}"
}

function _check_results {
  obs=$1
  exp=$2
  if ! diff ${obs} ${exp} &> ./difference; then

    echo "obs-----"
    cat ${obs}
    echo "exp-----"
    cat ${exp}
    echo "--------"

    echo "- [FAIL] ${curr_case}"
    cat ./difference 
    exit 1
  fi
}

function _run_script {
  cat ./infile.tsv | awk -f ${awk_f1} -f ${awk_f2} -vnotGCTA="notGCTA.out" -vpalin="palin.out" -vhomvar="hom.out" -vnotExpA2="notExpA2.out" -vnotPossPairs="notPossPair.out" -vindel="indel.out" > ./observed-result1.tsv

  _check_results ./observed-result1.tsv ./expected-result1.tsv

  echo "- [OK] ${curr_case}"

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# Case 1

_setup "effect flips"

cat <<EOF > ./infile.tsv
1	T	C	3:140461721	rs6439928	T	C
10	T	C	7:43168054	rs6463169	C	T
1000	A	G	2:28958241	rs10197378	G	A
1002	A	G	18:31901577	rs12709653	A	G
1003	A	G	1:154199074	rs12726220	A	G
1005	T	C	1:8413753	rs12754538	C	T
1008	T	C	10:118368257	rs12767500	C	T
101	A	G	4:10060702	rs6834555	G	A
1010	T	C	10:36429198	rs12771570	C	T
1011	A	G	2:212083137	rs10201617	G	A
EOF

#output columns "0\tA1\tA2\tCHRPOS\tRSID\tEffectAllele\tOtherAllele\tEMOD" 
cat <<EOF > ./expected-result1.tsv
1	T	C	3:140461721	rs6439928	T	C	1
10	T	C	7:43168054	rs6463169	C	T	-1
1000	A	G	2:28958241	rs10197378	G	A	-1
1002	A	G	18:31901577	rs12709653	A	G	1
1003	A	G	1:154199074	rs12726220	A	G	1
1005	T	C	1:8413753	rs12754538	C	T	-1
1008	T	C	10:118368257	rs12767500	C	T	-1
101	A	G	4:10060702	rs6834555	G	A	-1
1010	T	C	10:36429198	rs12771570	C	T	-1
1011	A	G	2:212083137	rs10201617	G	A	-1
EOF

_run_script

#---------------------------------------------------------------------------------
# Case 2

_setup "allele flips"

#input columns: 0	A1	A2	CHRPOS	RSID	A1	A2
cat <<EOF > ./infile.tsv
1	A	G	3:140461721	rs6439928	T	C
10	T	C	7:43168054	rs6463169	C	T
1000	A	G	2:28958241	rs10197378	G	A
1002	T	C	18:31901577	rs12709653	A	G
1003	A	G	1:154199074	rs12726220	A	G
1005	A	G	1:8413753	rs12754538	C	T
1008	T	C	10:118368257	rs12767500	C	T
101	A	G	4:10060702	rs6834555	G	A
1010	T	C	10:36429198	rs12771570	C	T
1011	A	G	2:212083137	rs10201617	G	A
EOF

#output columns: "0\tA1\tA2\tCHRPOS\tRSID\tEffectAllele\tOtherAllele\tEMOD" 
cat <<EOF > ./expected-result1.tsv
1	A	G	3:140461721	rs6439928	T	C	1
10	T	C	7:43168054	rs6463169	C	T	-1
1000	A	G	2:28958241	rs10197378	G	A	-1
1002	T	C	18:31901577	rs12709653	A	G	1
1003	A	G	1:154199074	rs12726220	A	G	1
1005	A	G	1:8413753	rs12754538	C	T	-1
1008	T	C	10:118368257	rs12767500	C	T	-1
101	A	G	4:10060702	rs6834555	G	A	-1
1010	T	C	10:36429198	rs12771570	C	T	-1
1011	A	G	2:212083137	rs10201617	G	A	-1
EOF

_run_script


