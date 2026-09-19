#!/bin/bash
set -e
#
# ESLintを実行するラッパースクリプト。
#
# 環境変数:
#   NODE_PROJECT_DIR  package.json のあるディレクトリ(デフォルト: カレントディレクトリ)
#   ESLINT_CONFIG     使用するESLint共通設定ファイル(デフォルト: 本リポジトリの共通ルール)
#
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG="${ESLINT_CONFIG:-$SCRIPT_DIR/configs/node/.eslintrc.common.cjs}"

# NODE_PROJECT_DIR未指定時は、frontend/package.json → ./package.json の順に自動検出する
if [ -n "$NODE_PROJECT_DIR" ]; then
  PROJECT_DIR="$NODE_PROJECT_DIR"
elif [ -f "frontend/package.json" ]; then
  PROJECT_DIR="frontend"
else
  PROJECT_DIR="."
fi

echo "[eslint] project=${PROJECT_DIR} config=${CONFIG}"

cd "$PROJECT_DIR"
npx eslint --fix --config "$CONFIG" .
