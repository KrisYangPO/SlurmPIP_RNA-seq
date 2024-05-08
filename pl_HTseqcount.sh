#!/bin/bash
# htseq human genome

# parameters
inputpath=$1
outputpath=$2
core=$3
species=$4


# index:
# 用判斷式判斷 speci 裡面有沒有 mouse/human 字串。
if [[ $species == *'mouse'* ]]; then
  gtf=/staging/biology/ls807terra/0_genomes/genome_gtf/mm10/mm10.refGene.gtf

elif [[ $species == *'human'* ]]; then
  gtf=/staging/biology/ls807terra/0_genomes/genome_gtf/CHM13/CHM13_v2.0.gtf

fi


# 抓取所有 bam 檔案，直接執行所有 htseq-count
cd ${inputpath}
samples=($(ls *.out.bam))


# Run HTseq-count
# files 要放在 gtf file 前面！！
htseq-count -m intersection-nonempty --nonunique all \
 -f bam -s reverse \
 -t exon \
 --idattr gene_name \
 -n ${core} \
 ${samples[@]} \
 ${gtf} \
 > ${outputpath}/HTseq_count_Allbam.txt

echo "Species: "${species}
echo "GTF file: "$(basename ${gtf})


