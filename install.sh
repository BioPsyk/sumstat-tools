
# Chek if PWD already exists in PATH
while IFS=';' read -ra ADDR; do
  for el in "${ADDR[@]}"; do
    if [ "${PWD}" == "${el}" ]; then
      echo "sumstat-tools already exists in path"
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
echo " export PATH=${PWD}:\${PATH}" >> ${HOME}/.bashrc
echo "added 'export PATH=${PWD}:\${PATH}' to ${HOME}/.bashrc"

