#!/bin/bash

#################################################################################
#                                                                               #
# Copyright (c) 2012 takahiro_ikeuchi @iktakahiro                               #
#                                                                               #
# Permission is hereby granted, free of charge, to any person obtaining a copy  #
# of this software and associated documentation files (the "Software"), to deal #
# in the Software without restriction, including without limitation the rights  #
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell     #
# copies of the Software, and to permit persons to whom the Software is         #
# furnished to do so, subject to the following conditions:                      #
#                                                                               #
# The above copyright notice and this permission notice shall be included in    #
# all copies or substantial portions of the Software.                           #
#                                                                               #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR    #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,      #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE   #
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER        #
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, #
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN     #
# THE SOFTWARE.                                                                 #
#                                                                               #
#################################################################################

#################################################################################
#
# 引数の解説
# 1 : 対象ファイル名
# 2 : クロス集計の行にするカラム 自然数を指定
# 3 : クロス集計の列にするカラム 自然数を指定
# 4 : グループ化して合計値を算出するカラム 自然数を指定
# 5 : 対象ファイルの形式 c = CSV, t = TSV, 省略 = CSV
# 6 : デバッグモード d = 有効 一時ファイルを削除しない, 省略 = 無効
#
# 実行例 : sh crosstabj_3_columns.sh sample.txt 1 2 3 c
#          sh crosstabj_3_columns.sh hoge.txt 5 8 2 t
#
#################################################################################

# sort高速化のためのおまじない
export LC_ALL=C

# 引数を受け取る
TARGET_FILE=$1
KEY_COLUMN=$2
VALUE_COLUMN=$3
SUM_COLUMN=$4

case $5 in
        c) DELIMITER_INPUT=',';;
        t) DELIMITER_INPUT='\t';;
        *) DELIMITER_INPUT=',';;
esac

case $6 in
	d) DEBUG_MODE=1;;
	*) DEBUG_MODE=0;;
esac

# 内部処理はカンマで実行する（変更不要）
DELIMITER_OUTPUT=','

# Validation用の設定
MIN_ARGS=4
MAX_ARGS=6

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
func_check_numeric ${VALUE_COLUMN}
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
calc_dir=`mktemp -d -p ./`
cd ${calc_dir}
echo "作業ディレクトリは${calc_dir} です"

# カラム抽出
date
echo "カラム抽出処理を開始"

cat ../${TARGET_FILE} |awk -v KEY_COLUMN=${KEY_COLUMN} -v VALUE_COLUMN=${VALUE_COLUMN} -v SUM_COLUMN=${SUM_COLUMN} -v DELIMITER_INPUT=${DELIMITER_INPUT} -v DELIMITER_OUTPUT=${DELIMITER_OUTPUT} 'BEGIN { FS = DELIMITER_INPUT; OFS = DELIMITER_OUTPUT } ; {print $KEY_COLUMN, $VALUE_COLUMN, $SUM_COLUMN}' > tmp_data.txt

# スラッシュがあるとこけるのでハイフンに置換（効率が悪いので今後対処予定
sed -i -e 's/\//-/g'  tmp_data.txt

date
echo "カラム抽出処理を完了"

date
echo "表頭と表側の抽出開始"

array_key=()
array_key=(`cut -f 1 -d , tmp_data.txt |sort -u`)

array_value=()
array_value=(`cut -f 2 -d , tmp_data.txt |sort -u`)

# rownameの作成
for key in ${array_key[@]}
do
	echo ${key} >> rowname.txt
done

# headerの作成
for value in ${array_value[@]}
do
	echo ${value} >> tmp_header.txt
done

tr '\n' '\t' < tmp_header.txt > header.txt

sed -i -e "1s/^/\t/" header.txt
sed -i -e "1s/\t$/\n/" header.txt

echo "表頭と表側の抽出完了"

# 集計処理
date
echo "集計処理の開始"
awk -F, '{print > "pre_multi_"$2}' tmp_data.txt

for file in ${array_value[@]}
do
	awk -F, '{a[$1]+=$3;}END{for(i in a)print i","a[i];}' pre_multi_${file} | sort -t 1 > sort_${file}
	join -t ',' -1 1 -2 1 -a 1 rowname.txt sort_${file} | awk -F, '{print $2}' | sed 's/^$/0/g' > split_sum_${file}

done

cp header.txt sum_result.txt
paste rowname.txt split_sum_* >> sum_result.txt

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
