#!/bin/bash
set -e
#
# コミットメッセージが Conventional Commits 形式に沿っているかをチェックする
# スクリプト(commit-msg フックから呼び出される)。
#
# npmの`commitlint`と同等のチェックを、Node.jsに依存せず実現するため
# bashの正規表現で自作している。これによりJava/Python等、Node.jsが
# 入っていない環境のプロジェクトでも同じチェックを使い回せる。
#
# 期待する形式: <type>(<scope>): <subject>
#   例: feat(user): ユーザー一覧APIを追加
#       fix: ログイン時のNullPointerExceptionを修正
#
COMMIT_MSG_FILE="$1"
PATTERN="^(feat|fix|docs|style|refactor|perf|test|chore|build|ci|revert)(\([a-zA-Z0-9_./-]+\))?!?: .+"

FIRST_LINE="$(head -n1 "$COMMIT_MSG_FILE")"

# マージコミットや、revertが自動生成するメッセージは対象外とする
if echo "$FIRST_LINE" | grep -Eq "^(Merge |Revert )"; then
  exit 0
fi

if ! echo "$FIRST_LINE" | grep -Eq "$PATTERN"; then
  echo "----------------------------------------------------------------------"
  echo "[commit-msg-check] コミットメッセージがConventional Commits形式ではありません。"
  echo ""
  echo "  現在のメッセージ : ${FIRST_LINE}"
  echo ""
  echo "  期待する形式     : <type>(<scope>): <subject>"
  echo "  例               : feat(user): ユーザー一覧APIを追加"
  echo ""
  echo "  使用可能なtype   : feat, fix, docs, style, refactor, perf, test, chore, build, ci, revert"
  echo "----------------------------------------------------------------------"
  exit 1
fi

echo "[commit-msg-check] OK: ${FIRST_LINE}"
