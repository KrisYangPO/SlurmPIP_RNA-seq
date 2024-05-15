#!/bin/bash
# htseq human genome

# parameters
sampleID=$1
inputpath=$2
outputpath=$3
core=$4
species=$5


# index:
# 用判斷式判斷 speci 裡面有沒有 mouse/human 字串。
if [[ $species == *'mouse'* ]]; then
  gtf=/staging/biology/ls807terra/0_genomes/genome_gtf/mm10/mm10.refGene.gtf

elif [[ $species == *'human'* ]]; then
  gtf=/staging/biology/ls807terra/0_genomes/genome_gtf/CHM13/CHM13_v2.0.gtf

fi


# 抓取所有 bam 檔案，直接執行所有 htseq-count
cd ${inputpath}
sample=$(ls ${sampleID}_*.out.bam)


# Run HTseq-count
# files 要放在 gtf file 前面！！
htseq-count -m intersection-nonempty --nonunique all \
 -f bam -s reverse \
 -t exon \
 --idattr gene_name \
 -n ${core} \
 ${sample} \
 ${gtf} \
 > ${outputpath}/HTseq_${sampleID}.txt


echo "Sample: "${sampleID}
echo "Species: "${species}
echo "GTF file: "$(basename ${gtf})


