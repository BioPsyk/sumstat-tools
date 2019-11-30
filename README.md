
# Table of Contents
* [sumstat-tools-intro](#sumstat-tools-intro)
* [download-and-install](#download-and-install)
* [structure-of-tools](#structure-of-tools)
* [user-config](#user-config)
* [sstools-gb](#sstools-gb)

# <a name="sumstat-tools-intro"></a>sumstat-tools-intro
Tools for curating and filtering sumstats

# <a name="download-and-install"></a>download-and-install
To download and install sumstat-tools you have to clone the latest version from github. 

```shell 
# Step 1: Download using git clone
git clone 

# Step 2: Enter directory
cd sumstat-tools

# Step 3: Execute install to set sumstat-tools in path
./install

# Step 4: Source .bashrc to finalize installation
source ${HOME}/.bashrc

# Step 5: Verify that sstools starts
sstools-version

```
NOTE: After the path has been set, the cloned directory cannot be moved without a running ./install again from the new path 

# <a name="The-sumstat-tools-software-suit"></a>The-sumstat-tools-software-suit
For the purpose of modularity the suit contains the set of relatively independent softwares listed below:

* sstools-raw
* sstools-gb
* sstools-stats
* sstools-asmbl

Each of these have in turn a modifier to perform a specific operation, for example:

* sstools-gb which
* sstools-gb lookup

# <a name="user-config"></a>user-config
sumstat-tools has all configuration files in the the ```config``` directory. 


# <a name="sstools-gb"></a>sstools-gb



