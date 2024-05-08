#!/bin/bash
# version 1

# Annotation:
: '
主要為了將 fastq 原始檔名稱裡，類似 "_22HMN2LT3" 的定序編號刪除，
就可以方便將 SampleID 用迴圈送去 pipeline 執行。

'

Path_fastq=$1
targetname=$2

cd ${Path_fastq}

for fq in $(ls *fastq*); do

  if [[ "$fq" == *"$targetname"* ]];then

    new=${fq/${targetname}/}
    mv ${fq} ${new}

  else
    echo "Erroneous pattern or pattern dosen't present in file name"

  fi; done

