#!/bin/bash

#################################################################################
#                                                                               
# Copyright (c) 2012 takahiro_ikeuchi @iktakahiro                               
#                                                                               
# Permission is hereby granted, free of charge, to any person obtaining a copy  
# of this software and associated documentation files (the "Software"), to deal 
# in the Software without restriction, including without limitation the rights  
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell     
# copies of the Software, and to permit persons to whom the Software is         
# furnished to do so, subject to the following conditions:                      
#                                                                               
# The above copyright notice and this permission notice shall be included in    
# all copies or substantial portions of the Software.                           
#                                                                               
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR    
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,      
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE   
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER        
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN     
# THE SOFTWARE.                                                                 
#                                                                               
#################################################################################

#################################################################################
#
# 引数の解説
# 1 : 対象ファイル名
# 2 : グループ対象するカラム 自然数を指定
# 3 : 合算するカラム 自然数を指定
# 4 : 対象ファイルの形式 c = CSV, t = TSV, 省略 = CSV
# 5 : デバッグモード d = 有効 一時ファイルを削除しない, 省略 = 無効
#
# 実行例 : sh simplesum_2columns.sh sample.txt 1 2 c
#          sh simplesum_2columns.sh hoge.txt 5 2 t
#
#################################################################################

# sort高速化のためのおまじない
export LC_ALL=C

# 引数を受け取る
TARGET_FILE=$1
KEY_COLUMN=$2
SUM_COLUMN=$3

case $4 in
        c) DELIMITER_INPUT=',';;
        t) DELIMITER_INPUT='\t';;
        *) DELIMITER_INPUT=',';;
esac

case $5 in
	d) DEBUG_MODE=1;;
	*) DEBUG_MODE=0;;
esac

# 内部処理はカンマで実行する（変更不要）
DELIMITER_OUTPUT=','

# Validation用の設定
MIN_ARGS=3
MAX_ARGS=5

## Validation
if [ $# -ge ${MIN_ARGS} ]; then
	:
else
	echo "ERROR : 引数の指定が不足しています。"
	exit 0;
fi

if test -e ${TARGET_FILE}; then
	:
else
	echo "ERROR : 指定したファイルが存在しません。"	
	exit 0;
fi

# func:数字のみ許可
function func_check_numeric() {
	test $1 -eq 0 2> /dev/null
	result=$?

	if [ ${result} -le 1 ]; then
		:
	else
		echo "ERROR : カラムの指定は整数のみ有効です。"
		exit 0;
	fi
}

func_check_numeric ${KEY_COLUMN}
func_check_numeric ${SUM_COLUMN}

# func:一時ファイル削除
function func_eraser() {
        rm -f header.txt
        rm -f tmp_header.txt
        rm -f tmp_data.txt
        rm -f rowname.txt
        find ./ -name "split_*" | xargs rm -f
        find ./ -name "sort_*" | xargs rm -f
        find ./ -name "pre_multi*" | xargs rm -f
}

## 処理開始
date
echo "作業ディレクトリを作成します"

# 作業ディレクトリの作成
calc_dir=`mktemp -d tmp.XXXXXXXXXX`

if [ $? -eq 0 ];then
	:
else
	echo "作業ディイレクトリの作成に失敗したため処理を中止します。"
	exit 0;
fi	

cd ${calc_dir}
echo "作業ディレクトリは${calc_dir} です"

# カラム抽出
date
echo "カラム抽出処理を開始"

cat ../${TARGET_FILE} |gawk -v KEY_COLUMN=${KEY_COLUMN} -v SUM_COLUMN=${SUM_COLUMN} -v DELIMITER_INPUT=${DELIMITER_INPUT} -v DELIMITER_OUTPUT=${DELIMITER_OUTPUT} 'BEGIN { FS = DELIMITER_INPUT; OFS = DELIMITER_OUTPUT } ; {print $KEY_COLUMN, $SUM_COLUMN}' > tmp_data.txt

# スラッシュがあるとこけるのでハイフンに置換（効率が悪いので今後対処予定
grep -E "/" tmp_data.txt >> /dev/null
if [ $? -ge 1 ];then
	:
else
	sed -i -e 's/\//-/g'  tmp_data.txt
fi

date
echo "カラム抽出処理を完了"

date
echo "キーの抽出開始"

array_key=()
array_key=(`cut -f 1 -d , tmp_data.txt |sort -n`)

echo "キーの抽出完了"

# 集計処理
date
echo "集計処理の開始"
gawk -F, '{print > "pre_multi_"$1}' tmp_data.txt

for file in ${array_key[@]}
do
	sum=`gawk -F, '{x+=$2}END{print x}' pre_multi_${file}`
	echo "${file},${sum}" > split_sum_${file}
done

cat split_sum_* >> sum_result.txt

date
echo "マージ処理完了！"

date
echo "ファイルをZIP圧縮しています。"
zip sum_result.zip sum_result.txt

date
echo "ZIP圧縮完了！成果物は${calc_dir}/sum_result.zip です！"

if [ ${DEBUG_MODE} -eq 0  ]; then
	echo "ディレクトリの掃除開始"
	func_eraser
	echo "ディレクトリの掃除完了"
fi

exit 0;
