#!/bin/bash
set -e
#
# SpotBugsを実行するラッパースクリプト。
#
# 環境変数:
#   JAVA_PROJECT_DIR   pom.xml のあるディレクトリ(デフォルト: カレントディレクトリ)
#
# JAVA_PROJECT_DIR未指定時は、backend/pom.xml → ./pom.xml の順に自動検出する
if [ -n "$JAVA_PROJECT_DIR" ]; then
  PROJECT_DIR="$JAVA_PROJECT_DIR"
elif [ -f "backend/pom.xml" ]; then
  PROJECT_DIR="backend"
else
  PROJECT_DIR="."
fi

echo "[spotbugs] project=${PROJECT_DIR}"

cd "$PROJECT_DIR"
mvn -q compile spotbugs:check
