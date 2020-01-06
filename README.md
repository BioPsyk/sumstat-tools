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
* [extra](#extra)

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
OUT_DIR0_sorted_index="out/raw_format_sorted_index"

# Make outfolder if it does not already exist
mkdir -p ${OUT_DIR0}
mkdir -p ${OUT_DIR0_sorted_index}
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
# Only checks for tab as separator, and that all rows have same number of fields
sstools-raw tab-sep -d ${DATA_DIR}
```

Seems like this Jansenetal file is troublesome. Let us count the field numbers for the top of the file to see if we can spot something obvious

```shell
#store bad file in variable
badfile1="AD_sumstats_Jansenetal.txt.gz"

#check number of fields when forcing tab separation
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

seems like one file only has 1 field. That is probably wrong, let us a try to correct it.

```shell
# Which file is bad
badfile2="TrynkaG_2011_22057235.txt.gz"
zcat ${DATA_DIR}/${badfile2} | head | awk 'BEGIN {FS="\t"}; {print NF }'

#analyze the separator composition (the new-sep function needs to be re-designed to improve how the replacing works, it is not 100% correct how FS and OFS is used in the underlying awk-script, but is still useful and therefore keept for now)
zcat ${DATA_DIR}/${badfile2} | sstools-raw new-sep -t "=tab=" -w "_" | head

#This is a very complicated field separation and needs special treatment.
zcat ${DATA_DIR}/${badfile2} | awk -vFS="" -vOFS="" '{gsub(/[[:space:]]/,"¬"); print $0}' |  awk -vFS="¬+" -vOFS="\t" '{for(k=2; k <= NF-1; k++){printf "%s%s", $(k), OFS } print ""}' | awk 'BEGIN {FS="\t"}; {print NF }' | head
zcat ${DATA_DIR}/${badfile2} | awk -vFS="" -vOFS="" '{gsub(/[[:space:]]/,"¬"); print $0}' |  awk -vFS="¬+" -vOFS="\t" '{for(k=2; k <= NF-1; k++){printf "%s%s", $(k), OFS } print ""}' | gzip -c > ${OUT_DIR0}/${badfile2}
```

#### copy over all files that we did not change

If the file looks alright we can link over the remaining files from the raw sumstat directory, or copy the files depending on available space (or if your virtual machine does not allow symlinks)

```shell
#here we are copying the files only if they don't already exist
for file in ${DATA_DIR}/*; do
  if [ -f "${OUT_DIR0}/$(basename ${file})" ]; then
    :
  else
    echo "$file"
    cp -n ${file} ${OUT_DIR0}/$(basename ${file})
  fi
done
```

From here we have correctly formatted files and are therefore prepared to use more automatic functionality in following steps. 

To further optimize the following algorithms, we can add an index to the raw file, and sort it. 

```shell
#Add index to all files and sort on index
for file in ${OUT_DIR0}/*; do
    echo "$file"
    zcat ${file} | sstools-raw add-index | sstools-raw sort-index | gzip -c >  ${OUT_DIR0_sorted_index}/$(basename ${file})
done
```

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
OUT_DIR2_sorted_index="${OUT_DIR2}/index_sorted"

# Make outfolder if it does not already exist
mkdir -p ${OUT_DIR1}
mkdir -p ${OUT_DIR2}
mkdir -p ${OUT_DIR2_sorted_index}
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
    sstools-gb which-wrap -d ${DATA_DIR} -m ${MAPFILE_GWAS} -o ${MAPFILE_GWAS_2} -i ${j}
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

However, sometimes it can worth to sort files on index for a little faster assembly.

```shell
# sort, index and rename first header column to '0' 
mkdir -p ${OUT_DIR2_ix}/successfull_mappings/GRCh37
for file in ${OUT_DIR2}/successfull_mappings/GRCh37/*; do
    echo "$file"
    cat ${file} |  awk -vOFS="\t" 'NR==1{$1="0"} {print $0}' | sstools-raw sort-index  >  ${OUT_DIR2_sorted_index}/successfull_mappings/GRCh37/$(basename ${file})
done
```

Now the tutorial for sstools-gb has come to an end.

## <a name="sstools-eallele"></a>sstools-eallele

Depending on array-specific annotation or reference annotations either the forward or reverse strand is reported in the final GWAS result. Additionally depending on the population, the effect allele could be any of a set of multi-allelic variants. To compare different GWAS studies we need to match them to a reference source. Here we are using dbsnp151 to do that.

A ground truth for our deduction algorithm is the table of complementary alleles:

| + | - |
|---|---|
| A | T |
| T | A |
| G | C |
| C | G |

The table is fundamental for out deduction algorithm, but also makes it difficult to discern between the complementary pairs AT and GC. For biallelic variants, where we have only the effect allele (A1) as source we then have these possible scenarios:

| Effect allele   | Possible source |
|----------|:-------------:|
| A or T |  A-T, T-A, A-G, G-A, A-C, C-A, T-G, G-T, T-C, C-T |
| G or C |  G-A, A-G, G-T, T-G, G-C, C-G, C-T, T-C, C-G, G-C |

That is a lot of options and we can't make any good conclusions. Luckily, if we have a database for each variant with the corresponding allele it can further reduce the number of possible variants. We will here use the reference allele for the effect allele in the corrected data. As you can see we still have a problem when both alleles in each strand pair constitutes the variant in the database.

| Effect allele   | db (ref-alt) | Possible source | New effect allele | Effect modifier |
|----------|:-------------:|:-------------:|:-------------:|:-------------:|
| A or T | A-G |  A-G  | A | 1 |
| A or T | G-A |  G-A  | G |-1 |
| A or T | A-T |  A-T, T-A  | A | -- |
| A or T | T-A |  T-A, A-T  | T | -- |

Extending the same methodology to multi-allelic variants we would get.

| Effect allele   | db (ref-alt1-alt2) | Possible source | New effect allele | Effect modifier |
|----------|:-------------:|:-------------:|:-------------:|:-------------:|
| A or T | A-G-C |  A-G, A-C  | A | 1 |
| A or T | G-A-C |  G-A, C-A  | G | -- |
| A or T | C-G-A |  C-A, G-A  | C | -- |
| A or T | A-G-T |  A-G, A-T, T-G | A | -- |

Fortunately, we are often provided with both the alleles used in the model. Not including multi-allelic variants we would get:

| Effect allele (A1 and A2)   | db (ref-alt) | Expected combinations | New effect allele | Effect modifier | Comment |
|----------|:-------------:|:-------------:|:-------------:|:-------------:|:-------------:|
| A or T and G or C | A-G |  A-G, T-C  | A | 1, -1 | A2 confirmed to be G  |
| A or T and G or C | A-C |  --  | A | -- | A2 is not the expected G |
| A or T and G or C | T-C |  T-C, A-G  | T | 1, -1 | A2 confirmed to be C  |
| A or T and G or C | T-G |  --  | T | -- | A2 is not the expected C |
| A or T and G or C | G-A |  G-A, C-T  | G | -1, 1 | A2 confirmed to be C  |
| A or T and G or C | C-A |  --  | C | -- | A2 is not the expected C |

In most cases we should be able to confirm A2, and it can be a good sanity check of the data to investigate the proportion of the not expected alleles.

Continuing to investigate palindromic SNPs to see if A2 provides any help in discerning the direction of effect:

| Effect allele (A1 and A2)   | db (ref-alt) | Possible source | New effect allele | Effect modifier | Comment |
|----------|:-------------:|:-------------:|:-------------:|:-------------:|:-------------:|
| A or T and T or A | A-T |  A-T, T-A  | A | -- | not possible finding the direction of effect  |
| A or T and T or A | A-C |  A-T, T-A  | A | -- | A2 is not the expected T  |

#### Reference alleles required

The reference database decides which allele is the new common effect allele to use for all sumstats. Here we are going to use the dbsnp151 alleles from sstools-gb as lookup and use the reference allele within dbsnp151 as the new common effect allele. Therefore, we have to specify our path to the raw sumstat file and the mapped file from sstools-gb.

```shell
# Specify path to input data (exists in the data folder of root of sumstat-tools)
DATA_DIR="data/gwas-summary-stats"

# Specify path to reference db
REF_DB_DIR="${OUT_DIR2}/successfull_mappings/GRCh37"
REF_DB_DIR_sorted_index="${OUT_DIR2_sorted_index}/successfull_mappings/GRCh37"

# Specify path to outfolder
OUT_DIR3="out/common_effect_allele"

# Make outfolder if it does not already exist
mkdir -p ${OUT_DIR3}

```

#### Assemble correct columns with ix

```shell
# Specify path to input data (exists in the data folder of root of sumstat-tools)
infile1="${DATA_DIR}/cad.add.160614.website.txt.gz"

# Specify path to reference db
REF_DB_FILE="${REF_DB_DIR}/remaining_cad.add.160614.website.txt"

# Assemble oiginal file with REF_DB_FILE
zcat $infile1 |  sstools-utils assemble  -g $REF_DB_FILE |  head

# Select and convert, to reduce RAM and get correct format
zcat $infile1 | sstools-utils ad-hoc-do -k "effect_allele|noneffect_allele" | head

# Combine select and reduce with assemble
zcat $infile1 | sstools-utils ad-hoc-do -k "effect_allele|noneffect_allele" |  sstools-utils assemble  -g $REF_DB_FILE | head

# Use as input to sstools-ealle (assemble command has a delay as it needs to store first file in memory, can be optimized using sort and join)
zcat $infile1 | sstools-utils ad-hoc-do -k "effect_allele|noneffect_allele" |  sstools-utils assemble  -g $REF_DB_FILE | head | sstools-eallele modifier -k "a1=1,a2=2,d1=7,d2=8,inx=3"

# If both the raw infile and the sucessfull mapping have a sorted index column, they can be merged mush faster and less memory consuming using the join command.
infile1_six="${OUT_DIR0_sorted_index}/cad.add.160614.website.txt.gz"
REF_DB_FILE_six="${REF_DB_DIR_sorted_index}/remaining_cad.add.160614.website.txt"
zcat $infile1_six | sstools-utils ad-hoc-do -k "0|effect_allele|noneffect_allele" |  sstools-utils assemble  -g $REF_DB_FILE_six -j | sstools-eallele modifier -k "a1=2,a2=3,d1=8,d2=9,inx=1" > ${OUT_DIR3}/refallele_cad.add.160614.website.txt
```
In the output from "sstools-eallele modifier" all lines not fulfilling conditions to calculate modifier are printed to stderr. This output will be very usefull both to get the common ref-allele and the correct effect-size modifier to get the corresponding direction of effect. 

## <a name="sstools-stats"></a>sstools-stats

Check statistics and create different formats from what is available.

In GWAS sumstat files we can have different types of test statistics, which can make it problematic to compare them to each other. Fortunately it is possible to calculate or infer missing statistics. The different statistics present are the following:

- Zscore
- Beta
- Odds Ratio
- P-value
- Standard error

To make things worse, we sometimes have values in log form, and sometimes not. The most problematic part is however that the naming of each of these statistics is very variable, so a lot of manual work of mapping of where each statistic is located in each file..

Using example data coming with the project we have designed this example to be runnnable just by starting from the projects root folder, therefore place yourself in the project root folder, and set the paths to the following (preferably the absolute paths):

```shell
#Raw data directory
DATA_DIR="data/gwas-summary-stats"

# Specify path to outfolder
OUT_DIR4="out/common_statistics"

# Make outfolder if it does not already exist
mkdir -p ${OUT_DIR4}
```

#### One file statistics extraction

Similar to how we treat sumstat data for genome build information we need to inspect and select an appropriate conversion to a common statistics variable.

```shell
# Select file we are about to lookup the genomic build information for
infile1_six="${OUT_DIR0_sorted_index}/cad.add.160614.website.txt.gz"

# Look at the header to see available field names
zcat $infile1_six | head -n3

# Declare params
beta_field_name="beta"
zscore_field_name="funx_Eff_Err_2_Z(beta,se_dgc)"

# Use beta and zscore in output
sstools-utils ad-hoc-do -f $infile1_six -k "${beta_field_name}|${zscore_field_name}" -n"new1,new2" | head
```

We not only want the correct statistics format output, but also making sure the measurement is associated to the right allele. To solve that we can use the effect allele modifier calculate in the previous section. 

```shell
# Declare params
effect_mod_file_six="out/common_effect_allele/refallele_cad.add.160614.website.txt"

# Convert the beta according to the modifier
sstools-utils ad-hoc-do -f $infile1_six -k "0|${beta_field_name}" -n"0,beta" | sstools-utils assemble  -g $effect_mod_file_six -j | head

# Convert the beta according to the modifier
sstools-utils ad-hoc-do -f $infile1_six -k "0|${beta_field_name}" -n"0,beta" | sstools-utils assemble  -g $effect_mod_file_six -j | awk -vOFS="\t" '{$2=$2*$5}'1 | head
sstools-stats modify -k "w=2,m=5" | head

sstools-utils ad-hoc-do -f $infile1_six -k "0|${beta_field_name}" -n"0,beta" | sstools-utils assemble  -g $effect_mod_file_six -j | awk -vOFS="\t" '{$2=$2*$5}'1 > ${OUT_DIR4}/modifiedstats_cad.add.160614.website.txt
```


## <a name="sstools-utils"></a>sstools-utils

There are many shared functionalities within this software suit, which we have tried to collect in the sstools-utils toolkit. Many examples of its usage is described within the previous sections. Here we try to focus on describing how to effectively merge output files of interest from the previous sections.


```shell
# Prepare paths to all files of interest
infile1_six="${OUT_DIR0_sorted_index}/cad.add.160614.website.txt.gz"
common_allele_and_stats=${OUT_DIR4}/modifiedstats_cad.add.160614.website.txt
position_GRCh37="${OUT_DIR2_sorted_index}/successfull_mappings/GRCh37/remaining_cad.add.160614.website.txt"

# Assemble the quality controlled set of data
sstools-utils ad-hoc-do -f $infile1_six -k "0|se_dgc" -n"0,SE" | sstools-utils assemble  -g $position_GRCh37 -j | sstools-utils assemble  -g $common_allele_and_stats -j  | head
```




## <a name="extra"></a>extra
This is code not necessary for the sstools workflow, but could be useful to know to add other features to the pipeline.

#### prepare dbsnp file
To be able to correct the alleles using the dbSNP file, it has to be downloaded and filter for multi-allelic variants.
This is how to do download and process the file using some simple awk commands.

```shell
#download a dbsnp vcf file from e.g.,
#https://ftp.ncbi.nih.gov/snp/organisms/human_9606/VCF/


#investigate how many multi-allelic variants we have for the available version.
zcat All_20180418.vcf.gz | grep -v '^[#;]' | awk 'index($4,",")==0{suma++} index($4,",")!=0{sumb++} index($5,",")==0{sumc++} index($5,",")!=0{sumd++} index($4,",")!=0 && index($5,",")!=0{sume++} index($4,",")==0 && index($5,",")==0{sumf++} index($4,",")!=0 || index($5,",")!=0{sumg++} END{printf "%-14s %s\n%-14s %s\n%-14s %s\n%-14s %s\n%-14s %s\n%-14s %s\n%-14s %s\n", "ref=1", suma, "ref>1", sumb, "alt=1", sumc, "alt>1", sumd, "ref>1&alt>1", sume, "ref=1&alt=1", sumf, "ref>1|alt>1", sumg}'

#Apply filter on multi allelic sites, and keep only the first 5 columns, which are the ones interesting for the allele check used by sstools.
zcat All_20180418.vcf.gz | grep -v '^[#;]' | awk 'index($4,",")==0 && index($5,",")==0{print $1,$2,$3,$4,$5}' | gzip -c >  All_20180418_no_multi_allelic.gz

#Make index
zcat All_20180418_no_multi_allelic.gz | awk '/^#/ {next;} ($3==".") {next;} {OFS="\t";print $3,$1,$2;}' | sort -k1,1 > All_20180418_no_multi_allelic.inx

#This takes a lot of time, so consider to set parallel=2 or higher (NOTE: setting parallel above 8 does not increase performance).
zcat All_20180418_no_multi_allelic.gz | awk '($3==".") {next;} {OFS="\t";print $3,$1,$2,$4,$5;}' | sort -k1,1 --parallel=2 | gzip -c > All_20180418_no_multi_allelic_sorted_rsid.gz

```
This file was supposed to later going to be used as input when correcting alleles.ed as input when correcting alleles. as input when correcting alleles.ed as input when correcting alleles. Now that functionality is already included in sstools-gb lookup.$3,$4,$5}' | gzip -c >  All_20180418_no_multi_allelic.gz

#Make index
zcat All_20180418_no_multi_allelic.gz | awk '/^#/ {next;} ($3==".") {next;} {OFS="\t";print $3,$1,$2;}' | sort -k1,1 > All_20180418_no_multi_allelic.inx

#This takes a lot of time, so consider to set parallel=2 or higher (NOTE: setting parallel above 8 does not increase performance).
zcat All_20180418_no_multi_allelic.gz | awk '($3==".") {next;} {OFS="\t";print $3,$1,$2,$4,$5;}' | sort -k1,1 --parallel=2 | gzip -c > All_20180418_no_multi_allelic_sorted_rsid.gz

# make two files, one sorted on chr-pos and one on rsid, both stripped to keep only first 5 columns.
zcat All_20180418.vcf.gz | grep -v '^[#;]' | awk -vOFS="\t" '{print $1,$2,$3,$4,$5}' > All_20180418.stripped

LC_ALL=C sort -k1,1 -k2,2 --parallel=8 All_20180418.stripped > All_20180418.stripped.chrpos.sorted
LC_ALL=C sort -k3,3 --parallel=8 All_20180418.stripped > All_20180418.stripped.rsid.sorted

# Filter the chrpos file on duplicates to only point to one rs-identifier per position. 

```