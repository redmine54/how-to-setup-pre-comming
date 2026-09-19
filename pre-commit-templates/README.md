# pre-commit-templates

全社共通の pre-commit hook / Lint設定 テンプレート集です。
SpringBoot+Vue、Tomcat+Java、Python、Node.js の各プロジェクトから参照します。

## 提供hook (.pre-commit-hooks.yaml)

| id | 対象 | 内容 |
|---|---|---|
| `checkstyle` | Java | 全社共通のコーディング規約チェック |
| `spotbugs` | Java | バグパターン検出 |
| `eslint-common` | JS/TS/Vue | Lintチェック(自動修正あり) |
| `prettier-common` | JS/TS/Vue/CSS | フォーマット(自動修正あり) |
| `gitleaks-common` | 全ファイル | ステージング済み差分の機密情報(APIキー・パスワード等)検出 |
| `commit-msg-check` | コミットメッセージ | Conventional Commits形式チェック(commitlint相当、Node.js不要) |

### gitleaks-common の前提条件

`gitleaks`本体がローカルにインストールされている必要があります。

\`\`\`bash
# macOS
brew install gitleaks

# Linux
# https://github.com/gitleaks/gitleaks/releases から実行バイナリを取得し、PATHの通った場所に配置
\`\`\`

### commit-msg-check を使う場合の追加設定

`commit-msg-check`はGitの`commit-msg`フックで動作するため、`pre-commit install`時に
`commit-msg`フックタイプも有効化する必要があります。利用側の`.pre-commit-config.yaml`に
以下を追記してください(設定すると`pre-commit install`一回で両方のフックが有効になります)。

\`\`\`yaml
default_install_hook_types: [pre-commit, commit-msg]
\`\`\`

設定していない場合は、以下のように明示的にインストールしてください。

\`\`\`bash
pre-commit install --hook-type pre-commit --hook-type commit-msg
\`\`\`

### なぜnpmの`commitlint`ではなく自作スクリプトなのか

`commitlint`はNode.jsパッケージのため、Java/Pythonのみのプロジェクト(Tomcat+Java、Python)に
導入するとNode.jsランタイムを追加でインストールする必要が生じます。本リポジトリでは
bashの正規表現でConventional Commits形式を検証する軽量スクリプトを自作することで、
4プロジェクトすべてで**追加ランタイム不要**で同じチェックを使い回せるようにしています。

## 使い方(利用側プロジェクト)

`.pre-commit-config.yaml` に以下のように追記します。

\`\`\`yaml
repos:
  - repo: https://gitlab.example.com/infra/pre-commit-templates
    rev: v1.0.0
    hooks:
      - id: checkstyle
      - id: spotbugs
      - id: eslint-common
        files: ^frontend/.*\.(js|ts|vue)$
      - id: prettier-common
        files: ^frontend/.*\.(js|ts|vue)$
\`\`\`

## ディレクトリ自動検出について

各スクリプトは `JAVA_PROJECT_DIR` / `NODE_PROJECT_DIR` が未指定の場合、
以下の優先順位でプロジェクトルートを自動検出します。

1. `backend/pom.xml`(Javaの場合)または `frontend/package.json`(Node系の場合)が存在すれば、そのディレクトリ
2. 存在しなければカレントディレクトリ(リポジトリ直下にソースがある構成向け)

`backend/frontend` 以外の名前でフォルダ分けしている場合は、環境変数で明示指定してください。

## ディレクトリ構成が標準(backend/frontend分割)と異なる場合

各スクリプトは環境変数でパスを上書きできます。

| 環境変数 | 対象hook | デフォルト値 |
|---|---|---|
| `JAVA_PROJECT_DIR` | checkstyle, spotbugs | `.`(カレントディレクトリ) |
| `NODE_PROJECT_DIR` | eslint-common, prettier-common | `.`(カレントディレクトリ) |
| `CHECKSTYLE_CONFIG` | checkstyle | 本リポジトリの `configs/java/checkstyle.xml` |
| `ESLINT_CONFIG` | eslint-common | 本リポジトリの `configs/node/.eslintrc.common.cjs` |
| `PRETTIER_CONFIG` | prettier-common | 本リポジトリの `configs/node/.prettierrc.common.json` |

利用側の `.pre-commit-config.yaml` で以下のように `entry` に環境変数を渡す形は
pre-commit標準の書式では直接指定できないため、リポジトリ直下に `.env` を置いて
`direnv` 等で読み込ませるか、CI側の `variables:` で設定してください。

## Pythonプロジェクトの場合

Black/Flake8/isort は pre-commit 公式repoをそのまま利用し、
共通ルールは `configs/python/pyproject.toml` をプロジェクトルートへコピーして使います。

\`\`\`bash
curl -o pyproject.toml \
  https://gitlab.example.com/infra/pre-commit-templates/-/raw/v1.0.0/configs/python/pyproject.toml
\`\`\`

## バージョン更新

\`\`\`bash
git tag v1.1.0
git push origin v1.1.0
\`\`\`

利用側プロジェクトは以下で一括更新できます。

\`\`\`bash
pre-commit autoupdate
\`\`\`
