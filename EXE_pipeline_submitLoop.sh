#!/bin/bash
# version 6. 可執行 trimgalore -> HTseq-count 的 RNA-seq pipeline.
# 新增參數：species 可以決定要用哪個物種 gtf file 執行。


# 版本需要更新內容
# ==============================================================================
: '
* 迴圈取得 sampleID 有問題：考慮原始檔用 "R1" 做抓取，但是沒有考慮是 single-end。
* 特殊檔案像是 index file, GTF 等要設計新的參數
  (testing)-> 可以直接設計參數選擇用 mouse/human genome 進行不同物種的分析。
  -> 或是可以將 gtf/index file 絕對路徑加入config_toolsPATH.sh 進行 source。

* HT-seq 把 bam 全部輸出可能會在每個 sample 執行時覆蓋同個檔案。
* HT-seq count 在執行(python)讀取 gtf file 時，會出現錯誤，可能是資料分隔的問題。'



# 版本更新解決：
# ==============================================================================
: '
(解決)* 在EXE/config 加入 species 參數，並由 STAR 還有 HTseq-count scripts 裡判斷式判斷。
(解決)* pipeline scripts 陣列輸入問題解決！
(解決)* 執行 EXE_pipeline_submitLoop.sh與原始檔位置不同 -> 直接修改成絕對路徑。
(解決)* 定序檔案都會有不一樣的序號 -> config_pruneFastqname.sh 直接修改原始檔檔名。 (line 68)'



# Annotation 使用說明：
# ==============================================================================
: '
1. 根據每次分析建立一個 pipeline_(projectname) 的資料夾，在資料夾建立 scripts folder
   在 scripts 裡放置所有 pipeline 相關 scripts。

2. 進入 EXE_pipeline_submitLoop 設定客製化的參數：
   (a) Path_main: 你的 pipeline_(projectname) 主要路徑。
   (b) Path_fastq: 你的原始檔案 fastq 路徑。
   (c) 加入你要做的分析 scripts: pipeline_scripts=(分析1 分析2 分析3 ...)
       每個分析要配合 config_pipeline_setting.sh 裡的設定。
       且加入 pipeline_scripts 陣列用空格分隔每個分析。
   (d) pruneString 是輸入原始檔名裡的定序編碼，每次定序產生的編碼不一樣。
   (e) 另外可以設定 Slurm partition。

3. (!!重要!!) pipeline scripts 將會照順序寫入一個陣列 pipeline_scripts 裡，
   再以 ${pipeline_scripts[@]} 輸入給 config_pipeline_setting.sh
   在 config_pipeline_setting.sh 裡面會有變數 pipeline_scripts=("$@") 儲存，
   但是前面已經有 $1~$7 等外部變數，會導致 ("$@") 將所有變數儲存成一個陣列。
   因此在 config_pipeline_setting.sh 裡 $1~$7 還有 pipeline_scripts=("$@") 之間
   要加上 shift 7，將前面 7 個變數取消掉在加入新的變數。'



# Input 資訊:
# ==============================================================================
: '
Input 檔案說明：
1. sampleID: 迴圈執行每個 samples (放置在 for loop 迴圈裡)
2. Path_main: 主要分析路徑 (pipeline_(projectname))。
3. Path_fastq: 原始檔 fastq 路徑。
4~7. scripts 執行最好輸入絕對路徑(sh... source...)
8. pipeline_scripts: 為一個陣列，裡面依序儲存分析流程的scripts。
'
Path_main=/staging/biology/ls807terra/
Path_fastq=/staging/biology/ls807terra/0_fastq/
SB_prj=MST109178
SB_part=186
SB_core=28
SB_mem=186
pipeline_scripts=(pl_trimfastqc.sh pl_STAR.sh pl_bamcoverage.sh pl_HTseqcount.sh)
pruneString=
sepcies=

# 定序編號盡量保留一個 "_"，最後檔名會變成
# ex: TE_ATRX_22HMN2LT3_R1.fastq.gz -> TE_ATRX_R1.fastq.gz



# 執行 PATH export
# ==============================================================================
source \
 ${Path_main}/scripts/config_toolsPATH_exprSource.sh \
 ${Path_main}/scripts/config_toolsPATH.sh

echo -e "\n--> Tools path are saved into PATH\n--> Initiate pipeline\n"



# 修改 fastq 原始檔檔名 (刪除定序序列名稱)
# ==============================================================================
: '
定序原始檔都會有類似：_22HMN2LT3 的檔案名稱夾在我們設計的檔案名稱裡。
因此要用變數帶入 scripts 將原始檔名稱進行去除。
pruneString 為原始檔定序編號的名稱 (要留一個 "_")'

# 定序編號盡量保留一個 "_"，最後檔名會變成
# ex: TE_ATRX_22HMN2LT3_R1.fastq.gz -> TE_ATRX_R1.fastq.gz

sh ${Path_main}/scripts/config_pruneFastqname.sh ${Path_fastq} ${pruneString}

# check
cd ${Path_fastq}
echo -e "\nPruned fastq name: "$(ls *fastq*)"\n"



# 執行 Pipeline
# 這裡要針對檔案名稱處理，或是直接複製這整段到 fastq 所在地執行。
# ==============================================================================
# 移動到主要路徑，建立 samples_report 檔，看看有沒有什麼檔案沒有被抓到。
cd ${Path_fastq}
touch ${Path_main}/samples_report.txt

for i in $(ls *_R1.fastq.gz); do

  # 原始檔的定序編號名稱已由 "config_pruneFastqname.sh" 修改成固定格式。
  sampleID=${i/_R1.fastq.gz/}
  echo -e "Sample ID:\t" ${sampleID} >> ${Path_main}/samples_report.txt

  # 以絕對路徑執行 pipeline 檔案。
  sh ${Path_main}/scripts/config_pipeline_setting.sh \
   ${sampleID} \
   ${Path_main} \
   ${Path_fastq} \
   ${SB_prj} \
   ${SB_part} \
   ${SB_core} \
   ${SB_mem} \
   ${sepcies} \
   ${pipeline_scripts[@]}

   sleep 3s

done



##

