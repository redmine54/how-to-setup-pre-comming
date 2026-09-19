#!/bin/bash
set -e
#
# infra/pre-commit-templates から共通のPython Lintルール(pyproject.toml)を
# 取得し、プロジェクトルートに配置するスクリプト。
# 初回セットアップ時、および共通ルール更新時に実行する。

TEMPLATE_REPO="https://gitlab.example.com/infra/pre-commit-templates"
TEMPLATE_REV="v1.0.0"

curl -o pyproject.toml \
  "${TEMPLATE_REPO}/-/raw/${TEMPLATE_REV}/configs/python/pyproject.toml"

echo "pyproject.toml を ${TEMPLATE_REV} の内容で更新しました。"
echo "black/isort/flake8 の設定はこのファイルの [tool.xxx] セクションを参照します。"
