#!/bin/bash
set -e
#
# infra/pre-commit-templates から共通のESLint/Prettierルール、および
# gitleaks/commit-msg-checkの共通スクリプトを取得し、プロジェクトルートに
# 配置するスクリプト。初回セットアップ時、および共通ルール更新時に実行する。
#
# SpringBoot+VueプロジェクトはCheckstyle等と同様に pre-commit経由で
# 共通repoを直接参照できるが、Node.js単体プロジェクト(Husky運用)は
# npm installだけで完結させたいため、設定ファイル/スクリプトをローカルに
# コピーする方式を採用している。

TEMPLATE_REPO="https://gitlab.example.com/infra/pre-commit-templates"
TEMPLATE_REV="v1.0.0"

curl -o .eslintrc.common.cjs \
  "${TEMPLATE_REPO}/-/raw/${TEMPLATE_REV}/configs/node/.eslintrc.common.cjs"

curl -o .prettierrc.common.json \
  "${TEMPLATE_REPO}/-/raw/${TEMPLATE_REV}/configs/node/.prettierrc.common.json"

curl -o .gitleaks-common.toml \
  "${TEMPLATE_REPO}/-/raw/${TEMPLATE_REV}/configs/common/gitleaks.toml"

mkdir -p .husky-scripts
curl -o .husky-scripts/commit-msg-check.sh \
  "${TEMPLATE_REPO}/-/raw/${TEMPLATE_REV}/scripts/common/commit-msg-check.sh"
chmod +x .husky-scripts/commit-msg-check.sh

echo "ESLint/Prettier/gitleaks/commit-msg-checkの共通ルールを ${TEMPLATE_REV} の内容で更新しました。"
