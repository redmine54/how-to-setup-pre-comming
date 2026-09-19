# pre-commit(Husky)セットアップ手順(Node.jsプロジェクト)

## 前提条件

- `gitleaks`本体がローカルにインストールされていること
  \`\`\`bash
  # macOS
  brew install gitleaks
  # Linux: https://github.com/gitleaks/gitleaks/releases から取得
  \`\`\`

## 手順

1. 依存パッケージをインストール(huskyの`prepare`スクリプトが自動でhookを設定する)
   \`\`\`bash
   npm install
   \`\`\`

2. 共通のESLint/Prettier/gitleaks/commit-msgチェックルールを取得
   \`\`\`bash
   npm run fetch-common-lint-rules
   \`\`\`

3. 動作確認のため、わざと規約違反のコードでコミットしてみる
   \`\`\`bash
   git add .
   git commit -m "test: pre-commitの動作確認"
   \`\`\`
   lint-stagedがステージング済みファイルにESLint/Prettierを適用し、
   自動修正できないエラーが残っていればコミットが中止される。
   続けてgitleaksが機密情報の混入をチェックし、最後にcommit-msg-check.shが
   コミットメッセージの形式(Conventional Commits)をチェックする。

4. コミットメッセージのチェックも確認する
   \`\`\`bash
   # 失敗する例(typeが無い)
   git commit -m "ユーザー一覧APIを追加"

   # 成功する例
   git commit -m "feat: ユーザー一覧APIを追加"
   \`\`\`

## 共通ルール更新時

`infra/pre-commit-templates` 側で新しいタグ(例: v1.1.0)が打たれたら、
`fetch_common_lint_rules.sh` 内の `TEMPLATE_REV` を更新してから再実行する。

\`\`\`bash
npm run fetch-common-lint-rules
\`\`\`

## SpringBoot+Vueプロジェクトとの違い

| 項目 | SpringBoot+Vue(frontend/) | Node.js単体プロジェクト |
|---|---|---|
| hookの実行主体 | pre-commitフレームワーク | Husky |
| 共通ルールの取り込み方 | `.pre-commit-config.yaml`のrepo参照(都度リモート実行) | `fetch_common_lint_rules.sh`でローカルにコピー |
| gitleaks/commit-msg-checkの呼び出し方 | `.pre-commit-config.yaml`で`gitleaks-common`/`commit-msg-check`を宣言するだけ | `.husky/pre-commit`・`.husky/commit-msg`から直接コマンド/スクリプトを呼び出す |
| 対象ファイル | ステージング済みファイルのみ(lint-staged) | 同左 |
