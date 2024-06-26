#!/bin/bash

# human CHM13 genome
# basic input
sampleID=$1
inputpath=$2
outputpath=$3
core=$4
species=$5

# index:
# 用判斷式判斷 speci 裡面有沒有 mouse/human 字串。
if [[ $species == *'mouse'* ]]; then
  index=/staging/biology/ls807terra/0_genomes/star_index/mm10_star_2.7.9

elif [[ $species == *'human'* ]]; then
  index=/staging/biology/ls807terra/0_genomes/star_index/CHM13_human

fi


# 移動到 input 位置，抓取檔案成檔案名稱陣列
# 根據 sample ID 找尋 (ls) 名稱，之後建立陣列：array=($(command))
cd ${inputpath}
samples=($(ls ${sampleID}_*.fq.gz))

# 計數陣列：有幾個 samples 被抓 (${#array[@]})
samples_len=${#samples[@]}

# report
echo "Target files: "${samples[@]}
echo "Number of samples: "${samples_len}


# !! STAR input 不需要額外設定他是要用 paired-end 或是 single-end 的分析 !!
# 所以直接將 ${samples[@]} array 裡面的內容都給 STAR


# program
STAR \
 --genomeDir ${index} \
 --runMode alignReads \
 --runThreadN ${core} \
 --readFilesCommand zcat \
 --readFilesIn ${samples[@]} \
 --outSAMprimaryFlag AllBestScore \
 --outMultimapperOrder Random \
 --outSAMtype BAM SortedByCoordinate \
 --outSAMattributes All \
 --outWigType wiggle \
 --outWigStrand Stranded \
 --outWigNorm RPM \
 --outFileNamePrefix ${outputpath}/${sampleID}_



# options:
: '
# outSAMattributes
sam 的 flags 要輸出哪些：全部

#  --outFilterMultimapNmax
alignment 被 mapping 到 genome 不同位置的次數上限
如果在數值內就會被 output 到 output file

'

