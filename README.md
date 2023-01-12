# sumstat-tools

A toolbox for GWAS summary statistics files.



## Download-and-install
To download and install sumstat-tools you have to clone the latest version from github.

```shell
# Step 1: place yourself in the folder you want to install sumstat-tools then git clone
git clone git@github.com:BioPsyk/sumstat-tools.git

# Step 2: Enter directory
cd sumstat-tools

# Step 3a: Execute install to set sumstat-tools in path
./install

# Step 4: Source .bashrc to finalize installation
source ${HOME}/.bashrc

# Step 5: Verify that sstools starts
sstools-version

# Step 6: Check the R installation and all required packages
# To be done

```
NOTE: After the path has been set, the cloned directory cannot be moved without running ./install again from the new path

```shell
# Run unit tests (run from project root)
./tests/run-unit-tests.sh
```

## <a name="user-config"></a>user-config
sumstat-tools has all configuration files in the ```config``` directory.


