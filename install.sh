# Check binary permissions
for filename in $PWD/bin/* 
do 
    if [ $(stat -c "%a" "$filename") != "770" ] 
    then 
        echo "File: ${filename#*sumstat-tools/} updated permission to 770" 
        chmod 770 $filename
    fi 
done 

for filename in $PWD/modules/bash-modules/sstools-init-modules/* 
do 
    if [ $(stat -c "%a" "$filename") != "770" ] 
    then 
        echo "File: ${filename#*sumstat-tools/} updated permission to 770" 
        chmod 770 $filename
    fi 
done 



# Chek if PWD already exists in PATH
while IFS=':' read -ra ADDR; do
  for el in "${ADDR[@]}"; do
    if [ "${PWD}/bin" == "${el}" ]; then
      echo "sumstat-tools already exists in path, so all should be installed"
      exit 1
    fi
  done
  echo "sumstat-tools is not already existing in path"
done <<< "${PATH}"

# Chek if .bashrc exists
if [ -f "${HOME}/.bashrc" ]; then
    echo "A .bashrc file exists "
else
    echo "A .bashrc file did not exist"
    echo "A .bashrc file is being created in ${HOME}"
fi

# Write to .bashrc
echo "" >> ${HOME}/.bashrc
echo "#path to sumstat-tools (added: $(date))" >> ${HOME}/.bashrc
echo "export PATH=${PWD}/bin:\${PATH}" >> ${HOME}/.bashrc
echo "added 'export PATH=${PWD}:\${PATH}' to ${HOME}/.bashrc"
echo "" >> ${HOME}/.bashrc

