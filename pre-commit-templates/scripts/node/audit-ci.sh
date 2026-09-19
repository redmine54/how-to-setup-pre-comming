#!/bin/bash
set -e
#
# audit-ci(npm audit をラップし、CIでの合否判定をしやすくしたツール)を実行し、
# npm依存パッケージに既知の脆弱性が含まれていないかチェックするラッパースクリプト。
#
# 環境変数:
#   NODE_PROJECT_DIR   package.json のあるディレクトリ(デフォルト: 自動検出)
#   AUDIT_CI_CONFIG    使用するaudit-ci設定ファイル(デフォルト: 本リポジトリの共通ルール)
#
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG="${AUDIT_CI_CONFIG:-$SCRIPT_DIR/configs/node/audit-ci.common.json}"

if [ -n "$NODE_PROJECT_DIR" ]; then
  PROJECT_DIR="$NODE_PROJECT_DIR"
elif [ -f "frontend/package.json" ]; then
  PROJECT_DIR="frontend"
else
  PROJECT_DIR="."
fi

echo "[audit-ci] project=${PROJECT_DIR} config=${CONFIG}"

cd "$PROJECT_DIR"
npx audit-ci --config "$CONFIG"
