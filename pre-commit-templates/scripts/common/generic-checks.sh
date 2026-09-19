#!/bin/bash
set -e
#
# pre-commitフレームワークの公式`pre-commit-hooks`リポジトリが提供する
# 基礎的なチェック(マージコンフリクトマーカー、秘密鍵、大容量ファイル等)を、
# Python(pre-commitフレームワーク)非依存で再現する軽量スクリプト。
#
# Husky運用のNode.jsプロジェクトは、Node.jsのみで完結させる設計方針のため、
# 本スクリプトはbashのみで実装している。
#
# 対象: git diff --cached (ステージング済みの変更)
#
FAILED=0

STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

if [ -z "$STAGED_FILES" ]; then
  exit 0
fi

# 1. マージコンフリクトマーカーの残存チェック
if echo "$STAGED_FILES" | xargs grep -lE '^(<<<<<<<|=======|>>>>>>>)' 2>/dev/null; then
  echo "[generic-checks] マージコンフリクトのマーカーが残っています。上記のファイルを確認してください。"
  FAILED=1
fi

# 2. 大容量ファイルの検出(デフォルト: 5MB超)
MAX_SIZE_KB="${MAX_FILE_SIZE_KB:-5120}"
for f in $STAGED_FILES; do
  if [ -f "$f" ]; then
    size_kb=$(du -k "$f" | cut -f1)
    if [ "$size_kb" -gt "$MAX_SIZE_KB" ]; then
      echo "[generic-checks] ${f} は ${size_kb}KB あり、上限(${MAX_SIZE_KB}KB)を超えています。"
      FAILED=1
    fi
  fi
done

# 3. 秘密鍵ファイルの誤コミット検出
for f in $STAGED_FILES; do
  if echo "$f" | grep -Eq '(id_rsa|id_ed25519|\.pem|\.key)$'; then
    if [ -f "$f" ] && grep -q "PRIVATE KEY" "$f" 2>/dev/null; then
      echo "[generic-checks] ${f} は秘密鍵のようです。コミット対象から除外してください。"
      FAILED=1
    fi
  fi
done

if [ "$FAILED" -ne 0 ]; then
  exit 1
fi

echo "[generic-checks] OK"
