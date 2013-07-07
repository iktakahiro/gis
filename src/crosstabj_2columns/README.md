# 機能説明

クロス集計を行うシェルスクリプトです。実行するとcurrent directoryに tmp. から始まるディレクトリが作成され、成果物 sum_result.zip が生成されます。

# 引数の解説

1. 対象ファイル名
1. クロス集計の行にするカラム 自然数を指定
1. クロス集計の列にするカラム 自然数を指定
1. 対象ファイルの形式 c = CSV, t = TSV, 省略 = CSV
1. デバッグモード d = 有効 一時ファイルを削除しない, 省略 = 無効

# 実行例

```sh
sh crosstabj_2columns.sh sample.txt 1 2 c
```

```sh
sh crosstabj_2columns.sh sample.txt 5 8 t
```
