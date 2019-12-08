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

# This step takes much less time and does not need parallization
for (( j=0; j<${nrows}; j++ )); do
sstools-utils assemble-wrap -d ${DATA_DIR} -m ${MAPFILE_GWAS} -g $mapdir -o $qcddir -i ${j}
done
```

Now the tutorial for sstools-gb has come to an end.
