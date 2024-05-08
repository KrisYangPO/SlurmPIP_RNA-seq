#!/bin/bash
# version 6: RNA-seq pipeline (STAR alignment)
# pipeline analysis covers: trimgalore, STAR, bamcoverage, and HTseq-count.
# 新增 species 選擇物種


# !! 版本修改：
# ==============================================================================
: '
* 特殊檔案像是 index file, GTF 等要設計新的參數
  -> 可以直接設計參數選擇用 mouse/human genome 進行不同物種的分析。
  -> 或是可以將 gtf/index file 絕對路徑加入config_toolsPATH.sh 進行 source。

* HT-seq 把 bam 全部輸出可能會在每個 sample 執行時覆蓋同個檔案。


(解決)* 還沒設計 scripts 要怎麼更新 -> 用外部變數帶入儲存 scripts 的陣列
(解決)* 當 fastq 不在計畫資料夾中，很難定位 scripts -> 直接用絕對路徑定位 scripts
(解決)* 設計可以回報當前分析路徑還有檔案輸入內容
(解決)* 將裡面的變數用外部變數帶入 -> $1~$7 外部變數帶入
(解決)* 目前 pipeline 長度延長到 bamcoverage
'



# Annotation 使用說明：
# ==============================================================================
: '
1. 每個 pipeline script 裡面開頭還是要有 #!/bin/bash 抬頭

2. scripts 所接收的是檔案絕對路徑，與 pipeline scripts 位置無關。

3. 在 EXE_pipeline_submit.sh 當中：
   pipeline 用到的 scripts 將會按順序寫入一個陣列：pipeline_scripts 裡，
   再以 ${pipeline_scripts[@]} 輸入給 config_pipeline_setting.sh

   在 config_pipeline_setting.sh 裡面會有變數 pipeline_scripts=("$@") 儲存，
   但是前面已經有 $1~$7 等外部變數，會導致 ("$@") 將所有變數儲存成一個陣列。

   因此在 config_pipeline_setting.sh 裡 $1~$7 還有 pipeline_scripts=("$@") 之間
   要加上 shift 7，將前面 7 個變數取消掉在加入新的變數。


4. pipeline_scripts=("$@") 要特別加上 () 原因是因為要把 $@ 所帶入的 script 陣列，
   進一步儲存成陣列才可以分別取用陣列裡的內容。
'



# Input parameters 還有 Path 資訊:
# ==============================================================================
: '
外部變數來源應來自 EXE_pipeline.sh 裡設定。
1. sampleID: 迴圈執行每個 sample。
2. Path_fastq: 原始檔 fastq 路境。
3. Path_main: 主要分析路徑。
4-7. Partition: Sbatch 參數。
8. species 物種是 mouse/human
9. pipeline_scripts=("$@")'

# 分析路徑
sampleID=$1
Path_main=$2
Path_fastq=$3
SB_proj=$4
SB_part=$5
SB_core=$6
SB_mem=$7
species=$8

# 跳過前面固定 7 個變數儲存剩下所有變數 (shift 7)
# 就可以用 $@ 儲存 EXE_pipeline_submit.sh 給予的 pipeline_scripts array
shift 8
pipeline_scripts=("$@")
Path_report=${Path_main}/report



# 其他函式:
# ==============================================================================
# A function to create folder
function mkFolder(){
name=$1
if [ ! -d ${Path_main}/${name} ]
then
mkdir ${Path_main}/${name}
fi
}



# report parameters
# ==============================================================================
echo -e "\n"
echo "Processing samples:   "${sampleID}
echo "Pipeline scripts has: "${pipeline_scripts[@]}
echo "SBATCH project:       "${SB_proj}
echo "SBATCH partition:     ""p"${SB_part}"G"
echo "SBATCH core:          "${SB_core}
echo "SBATCH memory:        "${SB_mem}"G"
echo "Species:              "${species}


# Pipeline
# Step1: trimgalore
# ==============================================================================
# annotation
: '
script: pl_trimfastqc.sh
input:
  1. sampleID (一組)
  2. fastqPath 指定到 fastq
  3. output 路徑
  4. core 數目'

echo "execute script: ""${pipeline_scripts[0]}"
# generate folder for trimmed output
mkFolder report
mkFolder Step1_output

# submit SBATCH job
A_JID=$(\
 sbatch \
  -A ${SB_proj} \
  -p ngs${SB_part}G \
  -c ${SB_core} \
  --mem=${SB_mem}g \
  -J Step1_${sampleID} \
  -o ${Path_report}/Step1_${sampleID}.o.txt \
  -e ${Path_report}/Step1_${sampleID}.e.txt \
  ${Path_main}/scripts/${pipeline_scripts[0]} \
  ${sampleID} \
  ${Path_fastq} \
  ${Path_main}/Step1_output \
  ${SB_core})

# prune Job.ID
A_JID=${A_JID/"Submitted batch job "/}
echo "Job ID: "${A_JID}" submitted"



# Step2: STAR
# ==============================================================================
# annotation
: '
script: pl_STAR.sh
input:
  1. sampleID (一組)
  2. input 路徑 (trimgalore: Step1_output)
  3. output 路徑 (output 會加上 sampleID 變成 sam 檔)
  4. core 數目
  5. species '

echo "execute script: ""${pipeline_scripts[1]}"
mkFolder Step2_output

B_JID=$(\
 sbatch \
  -A ${SB_proj} \
  -p ngs${SB_part}G \
  -c ${SB_core} \
  --mem=${SB_mem}g \
  -J Step2_${sampleID} \
  --dependency=afterok:${A_JID} \
  -o ${Path_report}/Step2_${sampleID}.o.txt \
  -e ${Path_report}/Step2_${sampleID}.e.txt \
  ${Path_main}/scripts/${pipeline_scripts[1]} \
  ${sampleID} \
  ${Path_main}/Step1_output \
  ${Path_main}/Step2_output \
  ${SB_core} \
  ${species})

# prune Job.ID
B_JID=${B_JID/"Submitted batch job "/}
echo "Job ID: "${B_JID}" submitted"



# Step3: bamcoverage
# ==============================================================================
# annotation
: '
script: pl_bamcoverage.sh
input:
  1. sampleID (一組)
  2. input路徑：Step2 (放置 sam2bam output)
  3. output路徑：Step4 (放置 bigwig)
  4. output format: bigwig
  5. core number

要注意在書寫 pl_bamcoverage.sh 時的 input 要特別用 *.rmdup.bam
因為只有 *.rmdup.bam 才有 bai 檔
'

echo "execute script: ""${pipeline_scripts[2]}"
mkFolder Step3_output

C_JID=$(\
 sbatch \
  -A ${SB_proj} \
  -p ngs${SB_part}G \
  -c ${SB_core} \
  --mem=${SB_mem}g \
  -J Step3_${sampleID} \
  --dependency=afterok:${B_JID} \
  -o ${Path_report}/Step3_${sampleID}.o.txt \
  -e ${Path_report}/Step3_${sampleID}.e.txt \
  ${Path_main}/scripts/${pipeline_scripts[2]} \
  ${sampleID} \
  ${Path_main}/Step2_output \
  ${Path_main}/Step3_output \
  bigwig \
  ${SB_core})

# prune Job.ID
C_JID=${C_JID/"Submitted batch job "/}
echo "Job ID: "${C_JID}" submitted"



# Step4: HTSeq-count
# ==============================================================================
# annotation
: '
script: pl_HTseqcount.sh
input:
  1. input 路徑：要記得是從 STAR output 的檔案作 input 路徑
  2. output 路徑
  3. core number
  4. species

gtf file 目前寫在 pl_HTseqcount.sh 裡
未來還要設計能夠選擇用 mouse/human genome 的參數'

echo "execute script: ""${pipeline_scripts[3]}"
mkFolder Step4_output

D_JID=$(\
 sbatch \
  -A ${SB_proj} \
  -p ngs${SB_part}G \
  -c ${SB_core} \
  --mem=${SB_mem}g \
  -J Step4_${sampleID} \
  --dependency=afterok:${C_JID} \
  -o ${Path_report}/Step4_${sampleID}.o.txt \
  -e ${Path_report}/Step4_${sampleID}.e.txt \
  ${Path_main}/scripts/${pipeline_scripts[3]} \
  ${Path_main}/Step2_output \
  ${Path_main}/Step4_output \
  ${SB_core} \
  ${species})

# prune Job.ID
D_JID=${D_JID/"Submitted batch job "/}
echo "Job ID: "${D_JID}" submitted"



#

