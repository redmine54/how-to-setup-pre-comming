#!/bin/bash
set -e
#
# gitleaksを実行し、ステージング済みの変更に機密情報(APIキー、パスワード等)が
# 含まれていないかチェックするラッパースクリプト。
#
# 前提: gitleaks本体がローカルにインストール済みであること
#   macOS : brew install gitleaks
#   Linux : https://github.com/gitleaks/gitleaks/releases から実行バイナリを配置
#
# 環境変数:
#   GITLEAKS_CONFIG  使用するgitleaks設定ファイル(デフォルト: 本リポジトリの共通ルール)
#
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG="${GITLEAKS_CONFIG:-$SCRIPT_DIR/configs/common/gitleaks.toml}"

if ! command -v gitleaks >/dev/null 2>&1; then
  echo "[gitleaks] gitleaksコマンドが見つかりません。"
  echo "  macOS: brew install gitleaks"
  echo "  Linux: https://github.com/gitleaks/gitleaks/releases からインストールしてください。"
  exit 1
fi

echo "[gitleaks] config=${CONFIG}"

# --staged: コミット対象(ステージング済み)の差分のみをスキャンする
gitleaks protect --staged --redact -v --config "$CONFIG"
