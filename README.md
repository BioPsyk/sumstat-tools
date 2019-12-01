# sumstat-tools

## Table of Contents
* [sumstat-tools-intro](#sumstat-tools-intro)
* [download-and-install](#download-and-install)
* [structure-of-tools](#structure-of-tools)
* [user-config](#user-config)
* [sstools-gb](#sstools-gb)

## <a name="sumstat-tools-intro"></a>sumstat-tools-intro
Tools for curating and filtering sumstats

## <a name="download-and-install"></a>download-and-install
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

# Step 6: Check the R installation and has all required packages
# To be done

```
NOTE: After the path has been set, the cloned directory cannot be moved without running ./install again from the new path

## <a name="The-sumstat-tools-software-suit"></a>The-sumstat-tools-software-suit
For the purpose of modularity the suit contains the set of relatively independent softwares listed below:

* sstools-raw
* sstools-gb
* sstools-stats
* sstools-asmbl

Each of these have in turn a modifier to perform a specific operation, for example:

* sstools-gb which
* sstools-gb lookup

## <a name="user-config"></a>user-config
sumstat-tools has all configuration files in the the ```config``` directory.



## <a name="sstools-gb"></a>sstools-gb

Sometimes GWAS sumstat data only report rsid and other times only chr:bp coordinates. This tool is supposed to support our pipeline with both versions of the genome build GRCh37 and GRCh38. This is done by indicating in each file, which field that contains any of these:
- chr
- position (bp)
- genome build (GRCh38 or GRCh37)
- rsid

For this we will provide the index information for each file, which then will be fed into an Rscript, which in turn calls the dbSNP151 annotation package from Bioconductor. It is also not obvious which genomic build the coordinates are aligned to therefore, and therefore we here provide a simple test to see to which build the given coordinates fits best.

Besides being fundamental in automatizing the mapping of genomic coordinates, we provide a 'pipeline' option to use a mapfile for all indices and transformations, an important addition to make a workflow reproducible.

Using example data coming with the project we have designed this example to cover as many situations as possible

#### In- and output directory
```shell
#Specify path to input data (exists in the data folder of root of sumstat-tools)
DATA_DIR="data/gwas-summary-stats"

#Specify path to outfolder
OUT_DIR="out/genomic_information"

# Make outfolder if it does not already exist
mkdir -p ${OUT_DIR}

```

#### One file simplest example
For the purpose of this example, we will first show the workflow for only one file.

```shell
# Select file we are about to lookup the genomic build information for
infile="${DATA_DIR}/cad.add.160614.website.txt.gz"

# Look at the header to see available field names
zcat $infile | head -n3

```
The file has both chromosome and basepair (bp) information, but is missing rsid. We make a quick test which coordinate build the coordinates belongs to (from the header it seems like hg19, but we run this script to be certain). Use 'sstools-gb which' to investigate this.

```shell
# Declare params
chr_field_name="chr"
bp_field_name="bp_hg19"

# Run
sstools-gb which -c ${chr_field_name} -p ${bp_field_name} -f ${infile}

```
The first column shows the best guess genome build based on the numbers to the right, for which column 1-4 represents the amount of rsids found for each of GRCh35 GRCh36 GRCh37 and GRCh38. Now knowing the present genome build, which appeared to be GRCh37 we can use that information to make a complete mapping of positions and rsids to GRCh37 and GRCh38, using the code below. The same required parameters as above and two new $gb and $OUT_DIR.

```shell
# Declare params
gb="GRCh37"

# Run
sstools-gb lookup -c ${chr_field_name} -p ${bp_field_name} -f ${infile} -g ${gb} -o ${OUT_DIR}

```
The results are not written to screen this time, but instead to the ${OUT_DIR} folder, which contains files for all markers that were not successful and files for the ones that were successful, both with indices referring back to the original file. Further down in this section it is shown how to merge the new mapped markers with the old file.

#### One file with difficult field names
Sometimes chromosome and postition information is in the same field name, e.g., chr1:342343. To handle that on the fly ```sstools-utils ad-hoc -lnb``` can provide us with a list of possible substitutes. Let us take a look at a file with a more complicated field name for the location and try to solve it using the ad-hoc function.

```shell
# Look at file
infile2="${DATA_DIR}/t2d_dom_dev.txt.gz"
zcat $infile2 | head

# take a look at the available special functions
sstools-utils ad-hoc -lnb

```
It seems like we have the location information on the form "1:749963", and the appropriate function would then be "funx_CHR_BP_2_BP". To see exactly what the different flags do, see ```sstools-utils ad-hoc -h```. Before using the computationally heavy sstools-gb, we can check that the special function gives the output we want.

```shell
# Test that we get the right output
sstools-utils ad-hoc -f $infile2 -k "funx_CHR_BP_2_BP(MarkerName)" | head

# Now do the gb check for this file using the special function.
sstools-gb which -c ${funx_CHR_BP_2_CHR(MarkerName)} -p ${funx_CHR_BP_2_BP(MarkerName)} -f ${infile}

```
This can be a good way of reducing the amount of intermediate files, and keeping track of which conversions that have been made. Now as a final step for this section we are going to merge our marker information for GRCh37 and GRCh38 with the original file.

```shell
# Merge the output by only keeping markers present in both
sstools-utils assemble -f $infile2 -g $mapped | head

```
Great it works as intended, we only get successfull mappings for GRCh37. That was it for the single file functionality. Next

#### Multiple files, how to make a convenient wrapper
To be able to check genome build for all sumstat files we first need a map file describing the indices for chr, pos or rsids are and their format. To make this task easier we a simple but efficient interactive walker, which steps through each file and asks for corresponding names and give suggestions on which index to use.

```shell
BASH_INTERACTIVE_MAPFILE="modules/bash-modules/interactive-mapfile-creator.sh"
METADATA_GWAS="tests/testdata/sample-metadata.txt"
MAPFILE_GWAS="${SSD_AGI}/mapfile-rsids-and-postitions.txt"
NEW_FILE_COLUMN_NAMES_AND_ORDER="CHR,BP,RSID"
#run bash function (to run it as a function is the only way to get the interactivenes to work)
source ${BASH_INTERACTIVE_MAPFILE}
interactiveWalker ${METADATA_GWAS} ${SSD1} ${MAPFILE_GWAS} ${NEW_FILE_COLUMN_NAMES_AND_ORDER}

```

Let us detect which genome build that has been used in each study corresponding to the coordinates present in the mapfile. This can take some time, and it might be worth aprallelize the for-loop.

```shell
METADATA_GWAS="tests/testdata/sample-metadata.txt"
MAPFILE_GWAS="${SSD_AGI}/mapfile-rsids-and-postitions.txt"
MAPFILE_GWAS_2="${SSD_AGI}/mapfile-genome-builds.txt"
Rlib="/home/projects/cu_10009/general/R-libraries/R_3.6.1_Bioc_3.9_library"
script="${PM}/R-modules/which-genome-build.R"

files=($(tail -n+2 ${METADATA_GWAS} | awk '{print $3}' ))
ids=($(tail -n+2 ${METADATA_GWAS} | awk '{print $1}' ))

#clear outfile
echo -e "study_id\tguessbuild\tGRCh35\tGRCh36\tGRCh37\tGRCh38"> ${MAPFILE_GWAS_2}

nrOfEntries=${#ids[@]}
# quick parallelization of for loop to gain some speed
for (( j=0; j<${nrOfEntries}; j++ )); do \
 ( \
 echo "$chr starting ..."; \

  id=${ids[j]}
  file=${files[j]}
  fileWpath=${SSD1}/${file}
  #pick row where id match to first column
  row2=($(tail -n+2 ${MAPFILE_GWAS} | awk -F"\t" -v id="${id}" '$1==id {for (i=2; i<=NF; i++) printf "%s%s",$(i),OFS;  }' ))

  res=($(Rscript $script $Rlib ${row2[0]} ${row2[1]} ${row2[2]} $fileWpath))
  printf "%s\t%s\t%s\t%s\t%s\t%s\n" $id ${res[0]} ${res[1]} ${res[2]} ${res[3]} ${res[4]} ${res[5]} | tee -a ${MAPFILE_GWAS_2}


 echo "$chr done ..."; \
 ) & \
done; wait


```

Now when we know which genome build we have, let us lift over everything that is GRCh37 to GRCh38 and then map to rsid, and create one more branch by lifting back to GRCh37 to create two versions containing variants both for two genome builds, and which are only present in dbSNP151. The result will be two files each containing: field1: ROWINDEX, field2: CHR, field3: BP field4: RSID

```shell

METADATA_GWAS="tests/testdata/sample-metadata.txt"
MAPFILE_GWAS="${SSD_AGI}/mapfile-rsids-and-postitions.txt"
MAPFILE_GWAS_2="${SSD_AGI}/mapfile-genome-builds.txt"
NEW_COORDINATES_DIR="${SSD_AGI}"
COMPLETED_COORDINATES="${SSD_AGI}/completed-conversions.txt"
LOG_DIR="${SSD_AGI}/completed-conversions"
Rlib="/home/projects/cu_10009/general/R-libraries/R_3.6.1_Bioc_3.9_library"
script="${PM}/R-modules/construct-GRCh37-and-GRCh38-rsid-mapped-coordinates.R"

#make dir if not exist
mkdir -p ${LOG_DIR}

#clear status file
echo -e "A mesage will be written to this file when it has finished"> ${COMPLETED_COORDINATES}

files=($(tail -n+2 ${METADATA_GWAS} | awk '{print $3}' ))
ids=($(tail -n+2 ${METADATA_GWAS} | awk '{print $1}' ))

nrOfEntries=${#ids[@]}
# quick parallelization of for loop to gain some speed
for (( j=0; j<${nrOfEntries}; j++ )); do \
 ( \
 echo "$chr starting ..."; \

  id=${ids[j]}
  file=${files[j]}
  fileWpath=${SSD1}/${file}
  #pick row where id match to first column
  row2=($(tail -n+2 ${MAPFILE_GWAS} | awk -F"\t" -v id="${id}" '$1==id {for (i=2; i<=NF; i++) printf "%s%s",$(i),OFS;  }' ))
  gb=($(tail -n+2 ${MAPFILE_GWAS_2} | awk -F"\t" -v id="${id}" '$1==id {for (i=2; i<=NF; i++) printf "%s%s",$(i),OFS;  }' ))

  Rscript ${script} ${Rlib} ${row2[0]} ${row2[1]} ${row2[2]} ${fileWpath} ${gb[0]} ${NEW_COORDINATES_DIR} 2> ${LOG_DIR}/${id}_genomebuild_conversion.log

  printf "%s\t%s\n" "done" ${id} >> ${COMPLETED_COORDINATES}

 echo "$chr done ..."; \
 ) & \
done; wait

```

Now we have output with all positions and rsids with index pointing to the original file. To save space we can wait to produce a joint file, and intead do it when assembling the final output in Step 04.
