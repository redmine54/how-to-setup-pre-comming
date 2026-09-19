#!/bin/bash
set -e
#
# OWASP Dependency-Checkを実行し、Mavenの依存ライブラリに既知の脆弱性(CVE)が
# 含まれていないかチェックするラッパースクリプト。
#
# 環境変数:
#   JAVA_PROJECT_DIR  pom.xml のあるディレクトリ(デフォルト: 自動検出)
#   CVSS_THRESHOLD    このCVSSスコア以上の脆弱性が見つかった場合に失敗とする(デフォルト: 7 = High以上)
#
# 注意: 初回実行時、NVD(National Vulnerability Database)のデータダウンロードに
#       時間がかかる場合がある(数分〜)。CIではキャッシュを効かせることを推奨(7章参照)。
#
if [ -n "$JAVA_PROJECT_DIR" ]; then
  PROJECT_DIR="$JAVA_PROJECT_DIR"
elif [ -f "backend/pom.xml" ]; then
  PROJECT_DIR="backend"
else
  PROJECT_DIR="."
fi

THRESHOLD="${CVSS_THRESHOLD:-7}"

echo "[dependency-check] project=${PROJECT_DIR} threshold=CVSS ${THRESHOLD}以上"

cd "$PROJECT_DIR"
mvn -q org.owasp:dependency-check-maven:check -DfailBuildOnCVSS="$THRESHOLD"
