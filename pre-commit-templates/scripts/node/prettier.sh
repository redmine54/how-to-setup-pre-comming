#!/bin/bash
set -e
#
# Prettierを実行するラッパースクリプト。
#
# 環境変数:
#   NODE_PROJECT_DIR  package.json のあるディレクトリ(デフォルト: カレントディレクトリ)
#   PRETTIER_CONFIG   使用するPrettier共通設定ファイル(デフォルト: 本リポジトリの共通ルール)
#
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG="${PRETTIER_CONFIG:-$SCRIPT_DIR/configs/node/.prettierrc.common.json}"

# NODE_PROJECT_DIR未指定時は、frontend/package.json → ./package.json の順に自動検出する
if [ -n "$NODE_PROJECT_DIR" ]; then
  PROJECT_DIR="$NODE_PROJECT_DIR"
elif [ -f "frontend/package.json" ]; then
  PROJECT_DIR="frontend"
else
  PROJECT_DIR="."
fi

echo "[prettier] project=${PROJECT_DIR} config=${CONFIG}"

cd "$PROJECT_DIR"
npx prettier --write --config "$CONFIG" .
