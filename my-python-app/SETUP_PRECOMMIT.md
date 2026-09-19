# pre-commit セットアップ手順(Pythonプロジェクト)

## 手順

1. 共通ルール(pyproject.toml)を取得
   \`\`\`bash
   ./fetch_common_lint_rules.sh
   \`\`\`

2. pre-commit本体をインストール
   \`\`\`bash
   pip install pre-commit
   pre-commit install
   \`\`\`

3. 初回は全ファイルに対して試験実行
   \`\`\`bash
   pre-commit run --all-files
   \`\`\`

## 共通ルール更新時

`infra/pre-commit-templates` 側で `pyproject.toml` が更新され、新しいタグ
(例: v1.1.0)が打たれたら、`fetch_common_lint_rules.sh` 内の `TEMPLATE_REV`
を更新してから再実行する。

\`\`\`bash
# fetch_common_lint_rules.sh 内
TEMPLATE_REV="v1.1.0"   # ← ここを更新
\`\`\`

\`\`\`bash
./fetch_common_lint_rules.sh
\`\`\`
