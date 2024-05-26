#!/bin/bash
: '
awk
刪除特定字元開頭的行'

input=$1
out=$2

# 為了避免選取到以 "#" 開頭或是 "空白" 的行，直接用正規表示法判斷 "是否為英文字開頭" 篩選欄位
awk -F "\t" 'BEGIN {OFS = "\t"} $1~/^[[:alnum:]]/{print $0}' ${input} > ${out}

