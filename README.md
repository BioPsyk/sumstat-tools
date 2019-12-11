# sumstat-tools

A toolbox of modularized software with the purpose of assisting a pipeline to control the quality of files with GWAS summary statistics.

## Table of Contents
* [sumstat-tools](#sumstat-tools)
* [download-and-install](#download-and-install)
* [user-config](#user-config)
* [structure-of-tools](#structure-of-tools)


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

# Step 6: Check the R installation and all required packages
# To be done

```
NOTE: After the path has been set, the cloned directory cannot be moved without running ./install again from the new path

## <a name="user-config"></a>user-config
sumstat-tools has all configuration files in the ```config``` directory.

## <a name="The-sumstat-tools-software-suit"></a>The-sumstat-tools-software-suit
For the purpose of modularity the suit contains the set of relatively independent softwares listed below:

* [sstools-raw](#sstools-raw)
* [sstools-gb](#sstools-gb)
* [sstools-stats](#sstools-stats)
* [sstools-utils](#sstools-utils)

Each of these have in turn a modifier with a set of parameter flags to perform a specific operation, for example:

* sstools-gb which -c -p -f
* sstools-gb lookup -c -p -f -g -o

## <a name="sstools-gb"></a>sstools-raw

A crude initial qauality control (QC) of GWAS sumstat data file format to be able to automatize the workflow in following steps.

Downloaded data from GWAS sumstat repositories is not always coming in the same
 format. A first requirement for the BioPsyk pipeline is that all files are:
- gzipped
- each field is separated by tab
- each row has same number of fields

For the majority of files this is already the case, but for those that are not, we
 here give examples of how to:
- test the conditons above
- correct files that break the conditions

Using example data coming with the project we have designed this example to be
runnnable just by starting from the projects root folder, **therefore place yourself in the project root folder**, and set the paths to the following (but when outside of this tutorial use absolute paths):

#### In- and output directory

```shell
#Specify path to input data (exists in the data folder of root of sumstat-tools)
DATA_DIR="data/gwas-summary-stats"

#Specify path to outfolder
OUT_DIR0="out/raw_format_ok"

# Make outfolder if it does not already exist
mkdir -p ${OUT_DIR0}
```

#### Test if files are gzipped correctly

One requirement for a file to work with sstools is to be gzipped. If there are any file which are not gzipped yet, you can make them by the gzip -c command. Here is an example of how to gunzip and gzip a file.

```shell
#unzip to get unzipped example
gunzip ${DATA_DIR}/AD_sumstats_Jansenetal.txt.gz

#gzip again to show how it is done
gzip -c ${DATA_DIR}/AD_sumstats_Jansenetal.txt > ${DATA_DIR}/AD_sumstats_Jansenetal.txt.gz

#remove unzipped file
rm ${DATA_DIR}/AD_sumstats_Jansenetal.txt

```
Check that the file is gzipped correctly

```shell
file="${DATA_DIR}/AD_sumstats_Jansenetal.txt.gz"
gzip -v -t ${file}
```

Check that the all files in directory are gzipped correctly

```shell
for file in ${DATA_DIR}/*;
do
  gzip -v -t ${file}
done
```

Seems like all files here are ok. In case a file is marked as badly gzipped, then try to use the original file and re-zip it again. Or download the sumstat file again.

#### Test if all rows have same number of tab separated fields

```shell
# Only checks for tab as separator
sstools-raw tab-sep -d ${DATA_DIR}
```

Seems like this Jansenetal file is troublesome. Let us count the field numbers for the top of the file to see if we can spot something obvious

```shell
#store bad file in variable
badfile1="AD_sumstats_Jansenetal.txt.gz"

#check number of fields when tab separation
zcat ${DATA_DIR}/$badfile1 | head | awk 'BEGIN {FS="\t"}; {print NF }'

```
In the output above we can see that the header has only 13 fields compared to the 14 fields in the following rows. One common problem for the tab format is if the header has been added to the sumstat file after it was generated. This can cause a discrepancy between number of detected fields for the header and the following rows. Here will perform a check of the header and make a manual correction if it is problematic.

```shell
# How does the header look like now
zcat ${DATA_DIR}/$badfile1 | head -n1

# try write new colnames and separate them with comma (,) and see if we get the number of fields to 14
newHeader="uniqID.a1a2,CHR,BP,A1,A2,SNP,Z,P,Nsum,Neff,dir,MAF,BETA,SE"
zcat ${DATA_DIR}/$badfile1 | sstools-raw new-header -c ${newHeader} | head | awk 'BEGIN {FS="\t"}; {print NF }'

# Unzip, include and gzip the change, and save the zip file to the folder with corrected data
zcat ${DATA_DIR}/$badfile1 | sstools-raw new-header -c ${newHeader} | gzip -c > ${OUT_DIR0}/${badfile1}
```

Check if there are any headers that is treated like only one field
```shell
for file in ${DATA_DIR}/*; do
  zcat ${file} | head -n1 | awk -v fil="${file}" 'BEGIN{FS="\t"}; {print NF, fil} '
done
```

seems like one file only has 1 field that is probably wrong, let us a try to correct it

```shell
# Which file is bad
badfile2="TrynkaG_2011_22057235.txt.gz"
zcat ${SSD}/${badfile2} | head | awk 'BEGIN {FS="\t"}; {print NF }'

#analyze the separator composition
zcat ${SSD}/${badfile2} | head |
awk 'BEGIN{FS="\t"; OFS="=TAB="}; {for(k=1; k <= NF; k++){printf "%s%s", $(k), OFS } print ""}' |
awk 'BEGIN{FS="[[:space:]]"; OFS="_"}; {for(k=1; k <= NF; k++){printf "%s%s", $(k), OFS } print ""}'

#first remove tabs replace with nothing, and then field separate on only whitespace (as well as skip the first column in the second iteration)
zcat ${SSD}/${badfile2} |
awk 'BEGIN{FS="\t"; OFS=""}; {for(k=1; k <= NF; k++){printf "%s%s", $(k), OFS } print ""}' |
awk 'BEGIN{FS="[[:space:]]+"; OFS="\t"}; {for(k=2; k <= NF; k++){printf "%s%s", $(k), OFS } print ""}' | gzip -c > ${SSD_CF}/${badfile2}.tmp

#check all is ok, and if so then rename file (getting rid of .tmp)
zcat ${SSD_CF}/$badfile2.tmp | head | awk '{print NF}'
mv ${SSD_CF}/${badfile2}.tmp ${SSD_CF}/${badfile2}
```

#### Prepare the remaining files for the next step

If the file looks alright we can link over the remaining files from the raw sumstat directory SSD.

```shell
#link over all files that were not modified (i.e., not bad files)
#for file in ${SSD}/*; do
#  file2=${file##*/}
#  echo "link ${file} ---and--- ${file2}"
#  ln -s ${file} ${SSD_CF}/${file2}
#done

#or copy, depending on available space (or if your virtual machine does not allow symlinks)
for file in ${SSD}/*; do
  file2=${file##*/}
  echo "copying ${file} ---to--- ${SSD_CF}/${file2}"
  cp -n ${file} ${SSD_CF}/${file2} || TRUE
done
```

From here we have correctly formatted files and are therefore prepared to use more automatic functionality in following steps.

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
OUT_DIR1="out/mapping_information"
OUT_DIR2="out/genome_location_information"

# Make outfolder if it does not already exist
mkdir -p ${OUT_DIR1}
mkdir -p ${OUT_DIR2}
```

#### One file simplest example
For the purpose of this example, we will first show the workflow for only one file.

```shell
# Select file we are about to lookup the genomic build information for
infile1="${DATA_DIR}/cad.add.160614.website.txt.gz"

# Look at the header to see available field names
zcat $infile1 | head -n3

```
The file has both chromosome and basepair (bp) information, but is missing rsid. We make a quick test which coordinate build the coordinates belongs to (from the header it seems like hg19, but we run this script to be certain). Use 'sstools-gb which' to investigate this.

```shell
# Declare params
chr_field_name="chr"
bp_field_name="bp_hg19"

# Run
sstools-gb which -c ${chr_field_name} -p ${bp_field_name} -f ${infile1}

```
The first column shows the best guess genome build based on the numbers to the right, for which column 1-4 represents the amount of rsids found for each of GRCh35 GRCh36 GRCh37 and GRCh38. Now knowing the present genome build, which appeared to be GRCh37 we can use that information to make a complete mapping of positions and rsids to GRCh37 and GRCh38, using the code below. The same required parameters as above and two new $gb and $OUT_DIR.

```shell
# Declare params
genome_build="GRCh37"

# Run
sstools-gb lookup -c ${chr_field_name} -p ${bp_field_name} -f ${infile1} -g ${genome_build} -o ${OUT_DIR2}

```
The results are not written to screen this time, but instead to the ${OUT_DIR} folder, which contains files for all markers that were not successful and files for the ones that were successful, both with indices referring back to the original file. Further down in this section it is shown how to merge the new mapped markers with the old file.

#### Another file with difficult field names
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
sstools-utils ad-hoc-do -f $infile2 -k "funx_CHR_BP_2_BP(MarkerName)" | head

# Now do the gb check for this file using the special function.
sstools-gb which -c "funx_CHR_BP_2_CHR(MarkerName)" -p "funx_CHR_BP_2_BP(MarkerName)" -f ${infile2}

# Now do the gb lookup for this file using the special function.
sstools-gb lookup -c "funx_CHR_BP_2_CHR(MarkerName)" -p "funx_CHR_BP_2_BP(MarkerName)" -f ${infile2} -g "GRCh37" -o ${OUT_DIR2}

```
This can be a good way of reducing the amount of intermediate files, and keeping track of which conversions that have been made. Now as a final step for this section we are going to merge our marker information for GRCh37 and GRCh38 with the original file.

```shell
# Merge the output by only keeping markers present in both
mapped2="${OUT_DIR2}/successfull_mappings/GRCh37/remaining_t2d_dom_dev.txt"
sstools-utils assemble -f $infile2 -g $mapped2 | head

# Do same for infile1
mapped1="${OUT_DIR2}/successfull_mappings/GRCh37/remaining_cad.add.160614.website.txt"
sstools-utils assemble -f $infile1 -g $mapped1 | head
```
Great! It works as intended, we got all successful mappings for GRCh37 in a joint output, which can be used in the downstream workflow.

#### Multiple files, how to make a convenient wrapper
We will here introduce how to manage batch mappings for the genome builds in an effective manner preserving modularity, which in practice means leaving for-loops outside the tools internal to facilitate the integration to a pipeline framework (otherwise making it impossible to make full use of pipeline managers such as e.g., NextFlow).

To be able to check genome build for all sumstat files we first need a map file describing the indices for chr, pos or rsids are and their format. To make this task easier we a simple but efficient interactive walker, which steps through each file and asks for corresponding names and give suggestions on which index to use.

In this section three new example files will be used to convince on the usefulness of the support mechanisms for to facilitate pipeline building. Let us set up these new settings

```shell
# declare input arguments
MAPFILE_GWAS="${OUT_DIR1}/mapfile-rsids-and-postitions.txt"
infile3="${DATA_DIR}/DIAGRAMv3.2012DEC17.txt.gz"
NEW_FILE_COLUMN_NAMES_AND_ORDER="CHR,BP,RSID"

#run bash function
sstools-utils interactive -f ${infile3} -o ${MAPFILE_GWAS} -n ${NEW_FILE_COLUMN_NAMES_AND_ORDER}

#check if we got anything in the outfile
cat ${MAPFILE_GWAS}

```
Now that we have initiated a mapfile, we could continue to add entries for more sumstat files to the same output file by just replacing the input file (-f), specify multiple files using comma separator (-f) or we can specify a complete directory (-d) to walk through. Files already present in the mapfile will be skipped.

```shell
# Add infiles to array
infiles="${infile1},${infile2},${infile3}"

# Run bash function
sstools-utils interactive -f ${infiles} -o ${MAPFILE_GWAS} -n ${NEW_FILE_COLUMN_NAMES_AND_ORDER}

# Check if we got anything in the outfile
cat ${MAPFILE_GWAS}

```
So, now we have fixed the manual step. Let us move on to use this newly created mapfile in the context of sstools-gb. Now we are again going to investigate which genome build that has been used in each study corresponding to the coordinates present in the mapfile. This can take some time, and it might be worth to parallelize the for-loop.

```shell
# Set a new outfile catching all genome build information
MAPFILE_GWAS_2="${OUT_DIR1}/mapfile-genome-builds.txt"

# Initiate outfile (clears already existing ones)
echo -e "study_id\tguessbuild\tGRCh35\tGRCh36\tGRCh37\tGRCh38" > ${MAPFILE_GWAS_2}

# Select files to run
inx=(1 2 3)

# Now we do the gb check in a simple bash job parallelization
for j in "${inx[@]}"; do \
( \
  echo "file $j starting ..."; \
  $(sstools-gb which-wrap -d ${DATA_DIR} -m ${MAPFILE_GWAS} -o ${MAPFILE_GWAS_2} -i ${j} )
  echo "file $j done ..."; \
) & \
done; wait

# After completion check all inferred genome builds (Takes roughly 3 minutes to run)
cat ${MAPFILE_GWAS_2}

```

If there is already a map out-file for genome builds, we should not have to run all files again. Here is how to get the indices for files missing genome build information.

```shell

# check which IDs in MAPFILE_GWAS that already are inside MAPFILE_GWAS_2
sstools-gb which-exists -m ${MAPFILE_GWAS} -g ${MAPFILE_GWAS_2}

# Change the flags to catch only the indices not in MAPFILE_GWAS_2
inx=($(sstools-gb which-exists -m ${MAPFILE_GWAS} -g ${MAPFILE_GWAS_2} -ki))

# Check which we should re-run the wrapper for (in this case zero entries)
echo "${inx[@]}"

```

Now when we know which genome builds we have, let us lift over everything that is GRCh37 to GRCh38 and then map to rsid. Also here we can use a parallelized setting.

```shell
# Set log dir to keep a log for each file
LOG_DIR="${OUT_DIR2}/log_files"

#make dir if not exists
mkdir -p ${LOG_DIR}

# Select files to run
inx=(1 2 3)

# Now we do the gb check in a parallelized loop for each file present in the mapfile
for j in "${inx[@]}"; do \
( \
echo "file $j starting ..."; \
sstools-gb lookup-wrap -d ${DATA_DIR} -m ${MAPFILE_GWAS} -g ${MAPFILE_GWAS_2} -o ${OUT_DIR2} -i ${j} -l ${LOG_DIR}
echo "file $j done ..."; \
) & \
done; wait

```

Similarly to which-exists, if there is already a map out-file for genome builds, we should not have to run all files again. Here is how to get the indices for files missing new location output.

```shell

# check which IDs in MAPFILE_GWAS that already have mappings in outputfolder
#sstools-gb lookup-exists -f ${MAPFILE_GWAS} -m ${MAPFILE_GWAS_2} )

# Change the flags to catch only the indices without mappings in outfolder
#inx=($(sstools-gb lookup-exists -f ${MAPFILE_GWAS} -m ${MAPFILE_GWAS_2} -ki))

# Check which we should re-run the wrapper for (in this case zero entries)
#echo "${inx[@]}"

```

Now we have output with all positions and rsids with index pointing to the original file. Therefore it is time to assemble a new  quality controlled set of files using the improved location information.

```shell
# Merge the output by only keeping markers present in both
mapdir="${OUT_DIR2}/successfull_mappings/GRCh37"
qcddir="${OUT_DIR2}/location_qcd_GRCh37"
mkdir -p "${qcddir}"

# Select files to run
inx=(1 2 3)

# This step takes much less time and does not need parallization
for j in "${inx[@]}"; do \
sstools-utils assemble-wrap -d ${DATA_DIR} -m ${MAPFILE_GWAS} -g $mapdir -o $qcddir -i ${j}
done

```

Now the tutorial for sstools-gb has come to an end.

## <a name="sstools-stats"></a>sstools-stats

Check statistics and create different formats from what is available.

In GWAS sumstat files we can have different types of test statistics, which can make it problematic to compare them to each other. Fortunately it is possible to calculate or infer missing statistics. The different statistics present are the following:

- Zscore
- Beta
- Odds Ratio
- P-value
- Standard error

To make things worse, we sometimes have values in log form, and sometimes not. The most problematic part is however that the naming of each of these statistics is very variable, so a lot of manual work of mapping of where each statistic is located in each file.

Therefore again we will have to create a mapfile, which will call awk scripts to perform the calculations we need. A benefit with using awk is that it is very fast, and in this pipeline we won't have to create any intermediate files for this maneuvor, but instead use this mapfile for the final assembly in step 4. Of course we will also show some custom examples of how we can call the functionality.

Using example data coming with the project we have designed this example to be runnnable just by starting from the projects root folder, therefore place yourself in the project root folder, and set the paths to the following (preferably the absolute paths):

```shell
#Specify path to this pipelines modules
PM="modules"

#Specify path to working directory
WD="test/testdata/testresults"

#Specify path to Step1 summary statistics files
SSD1="tests/testdata/01_format_corrected_sumstats"

#Specify path to folder for all transformed files
SSD_AGI="tests/testdata/02_genomic_information_to_add"
#make folder if it does not already exist
mkdir ${SSD_AGI}

```

#### One file map
The larger plan is to create a map file including all sumstat files, but for the purpose of this example, we will first show the workflow for only one file.

```shell
#select file we are about to add genomic informaiton to
selfile="AD_sumstats_Jansenetal.txt.gz"

#look at the header to see available field names
zcat ${SSD1}/$selfile | head -n3

```


## <a name="sstools-utils"></a>sstools-utils

There are many shared functionalities within this software suit, which we have tried to collect in the sstools-utils toolkit. All examples of usage is described within the other sections.
