#!/bin/bash
set -e
#
# Checkstyleを実行するラッパースクリプト。
#
# 環境変数:
#   JAVA_PROJECT_DIR   pom.xml のあるディレクトリ(デフォルト: カレントディレクトリ)
#   CHECKSTYLE_CONFIG  使用するCheckstyle設定ファイル(デフォルト: 本リポジトリの共通ルール)
#
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG="${CHECKSTYLE_CONFIG:-$SCRIPT_DIR/configs/java/checkstyle.xml}"

# JAVA_PROJECT_DIR未指定時は、backend/pom.xml → ./pom.xml の順に自動検出する
if [ -n "$JAVA_PROJECT_DIR" ]; then
  PROJECT_DIR="$JAVA_PROJECT_DIR"
elif [ -f "backend/pom.xml" ]; then
  PROJECT_DIR="backend"
else
  PROJECT_DIR="."
fi

echo "[checkstyle] project=${PROJECT_DIR} config=${CONFIG}"

cd "$PROJECT_DIR"
mvn -q checkstyle:check -Dcheckstyle.config.location="$CONFIG"
