# pre-commit 動作確認手順

## 前提

- `infra/pre-commit-templates` リポジトリが GitLab 上に作成済みで、
  `v1.0.0` タグが打たれていること。
- ローカルに Python(pip)、Java(mvn)、Node.js(npm) が導入済みであること。

## 手順

1. pre-commit本体をインストール
   \`\`\`bash
   pip install pre-commit
   \`\`\`

2. リポジトリルートに `.pre-commit-config.yaml` があることを確認
   (本ファイルと同じ階層に配置済み)

3. hookを有効化
   \`\`\`bash
   pre-commit install
   \`\`\`

4. 初回は全ファイルに対して試験実行してみる
   \`\`\`bash
   pre-commit run --all-files
   \`\`\`
   - `backend/` 配下の `.java` ファイルがあれば `checkstyle` / `spotbugs` が走る
   - `frontend/` 配下の `.js`/`.ts`/`.vue` ファイルがあれば `eslint-common` / `prettier-common` が走る

5. 実際にコミットしてみて、わざと規約違反のコードを混ぜた場合に
   コミットが中止されることを確認する
   \`\`\`bash
   git add .
   git commit -m "test: pre-commitの動作確認"
   \`\`\`

## うまく動かない場合のチェックポイント

| 症状 | 確認箇所 |
|---|---|
| `checkstyle`/`spotbugs`が実行されない | `backend/pom.xml` が存在するか、`files:` パターンが対象ファイルと一致しているか |
| `eslint-common`/`prettier-common`が実行されない | `frontend/package.json` が存在し、`npx eslint`/`npx prettier` がローカルで実行可能か |
| `repo`が見つからないエラー | `infra/pre-commit-templates` のURL・`rev`(タグ名)が正しいか、GitLabへのアクセス権があるか |
| Mavenがネットワークエラーになる | 社内プロキシ経由の設定(`~/.m2/settings.xml`)が必要な場合あり |
