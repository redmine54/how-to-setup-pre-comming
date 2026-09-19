# pre-commit構成 構築手順書

対象プロジェクト:
- SpringBoot + Vue(Vite)
- Tomcat + Java
- Python
- Node.js

添付ファイル:
- `pre-commit-templates.zip`(共通テンプレートリポジトリ本体)
- `my-springboot-vue-app-precommit-setup.zip`
- `my-tomcat-app-precommit-setup.zip`
- `my-python-app-precommit-setup.zip`
- `my-node-app-precommit-setup.zip`

---

## 1. 全体方針

コミット前に自動チェックを行い、異常があればコミット自体を中止する仕組み(pre-commitフック)を、4つの技術スタックへ横展開する。

ルールは `infra/pre-commit-templates` という共通リポジトリに一元管理し、各プロジェクトはそこを参照する構成とする。これはGitLab CI/CDのComponent化と同じ「1箇所で修正 → 全プロジェクトに反映」という発想に基づく。

```
infra/pre-commit-templates (共通ルール一元管理)
  ├─ SpringBoot+Vue → .pre-commit-config.yaml から直接参照
  ├─ Tomcat+Java    → .pre-commit-config.yaml から直接参照
  ├─ Python         → pyproject.toml をfetchスクリプトでコピー
  └─ Node.js        → eslintrc/prettierrc をfetchスクリプトでコピー
```

## 2. プロジェクト別の採用フレームワーク

| プロジェクト | 採用フレームワーク | 理由 |
|---|---|---|
| SpringBoot + Vue | pre-commitフレームワーク | Java(Maven)とJS/TSが1リポジトリに混在するため、言語非依存のフレームワークで一元管理 |
| Tomcat + Java | pre-commitフレームワーク | 同上(Java単体) |
| Python | pre-commitフレームワーク | Python公式のLintツール(black/flake8/isort)をそのまま利用 |
| Node.js | Husky + lint-staged | Node.js専用プロジェクトのため、npmエコシステムで完結する構成の方がシンプル |

### 2.1 横断的機能(全プロジェクト共通)

言語・フレームワークを問わず、以下の2機能は4プロジェクトすべてに共通で組み込む。

| 機能 | 目的 | 実現方法 |
|---|---|---|
| **gitleaks** | ステージング済みの差分に、APIキー・パスワード等の機密情報が含まれていないか検出する | gitleaks本体(Goバイナリ)をローカル/CIにインストールし、共通ルール(`gitleaks.toml`)で実行 |
| **commit-msg-check** | コミットメッセージがConventional Commits形式に沿っているか検証する(`commitlint`相当) | bashの正規表現で自作したスクリプト |

**なぜ`commitlint`ではなく自作スクリプトなのか**: `commitlint`はNode.js製パッケージであり、Tomcat+JavaやPythonのようなNode.jsを前提としないプロジェクトに導入すると、そのためだけにNode.jsランタイムを追加する必要が生じる。bashスクリプトで同等のチェックを自作することで、**4プロジェクトすべてで追加ランタイム不要**に統一している。

## 3. 各zipファイルの中身

### pre-commit-templates.zip(共通テンプレートリポジトリ)

```
pre-commit-templates/
├── .pre-commit-hooks.yaml         ← hookマニフェスト(提供hookの一覧を宣言)
├── README.md                      ← 使い方・環境変数一覧・前提条件
├── scripts/
│   ├── java/checkstyle.sh         ← Checkstyle実行ラッパー
│   ├── java/spotbugs.sh           ← SpotBugs実行ラッパー
│   ├── node/eslint.sh             ← ESLint実行ラッパー
│   ├── node/prettier.sh           ← Prettier実行ラッパー
│   └── common/
│       ├── gitleaks.sh            ← gitleaks実行ラッパー(新規)
│       └── commit-msg-check.sh    ← Conventional Commits検証(新規、Node.js不要)
└── configs/
    ├── java/checkstyle.xml        ← 共通Checkstyleルール
    ├── node/.eslintrc.common.cjs  ← 共通ESLintルール(Vue3+TS想定)
    ├── node/.prettierrc.common.json
    ├── python/pyproject.toml      ← 共通black/isort/flake8設定
    └── common/gitleaks.toml       ← 共通gitleaksルール(新規)
```

各スクリプトは `JAVA_PROJECT_DIR` / `NODE_PROJECT_DIR` が未指定の場合、`backend/pom.xml` や `frontend/package.json` の有無を見て自動的にプロジェクトルートを検出する。

提供hookの一覧(`.pre-commit-hooks.yaml`)は以下の通り。

| id | 対象 | 内容 |
|---|---|---|
| `checkstyle` | Java | 全社共通のコーディング規約チェック |
| `spotbugs` | Java | バグパターン検出 |
| `eslint-common` | JS/TS/Vue | Lintチェック(自動修正あり) |
| `prettier-common` | JS/TS/Vue/CSS | フォーマット(自動修正あり) |
| `gitleaks-common` | 全ファイル | ステージング済み差分の機密情報検出(新規) |
| `commit-msg-check` | コミットメッセージ | Conventional Commits形式チェック(新規) |

`gitleaks-common`を使うには、事前に**gitleaks本体のインストール**が必要(ローカル・CIランナー双方)。

```bash
# macOS
brew install gitleaks
# Linux: https://github.com/gitleaks/gitleaks/releases から実行バイナリを取得
```

### my-springboot-vue-app-precommit-setup.zip

```
my-springboot-vue-app/
├── .pre-commit-config.yaml   ← 共通テンプレートを rev: v1.0.0 で参照
└── SETUP_PRECOMMIT.md        ← 動作確認手順メモ
```

`checkstyle` / `spotbugs`(backend/配下)と `eslint-common` / `prettier-common`(frontend/配下)を、`files:` で対象パスを絞り込んで利用する。`gitleaks-common` / `commit-msg-check` はパス絞り込みなしでリポジトリ全体・コミットメッセージ全体に適用する。

`.pre-commit-config.yaml`には`default_install_hook_types: [pre-commit, commit-msg]`を追加しており、`pre-commit install`一回で`pre-commit`フックと`commit-msg`フックの両方が有効になる。

### my-tomcat-app-precommit-setup.zip

```
my-tomcat-app/
├── .pre-commit-config.yaml     ← 共通テンプレート参照(checkstyle, spotbugs, gitleaks-common, commit-msg-check)
├── pom.xml.snippet             ← pom.xmlに追記するプラグイン設定の抜粋
└── gitlab-ci-lint-snippet.yml  ← .gitlab-ci.yml の lint stage抜粋(gitleaksインストール手順込み)
```

リポジトリ直下に `pom.xml` がある単純な構成のため、Java系hookの`files:` の上書きは不要。

### my-python-app-precommit-setup.zip

```
my-python-app/
├── .pre-commit-config.yaml       ← black/isort/flake8(公式repo)+ gitleaks-common/commit-msg-check(共通repo)
├── fetch_common_lint_rules.sh    ← 共通pyproject.tomlを取得するスクリプト
├── gitlab-ci-lint-snippet.yml    ← .gitlab-ci.yml の lint stage抜粋(gitleaksインストール手順込み)
└── SETUP_PRECOMMIT.md            ← セットアップ手順
```

Lintツール自体は公式repoをそのまま使い、ルール設定(`pyproject.toml`)のみ共通リポジトリから取得する方式。`gitleaks-common`/`commit-msg-check`は、`.pre-commit-config.yaml`に`infra/pre-commit-templates`を追加で`repos:`参照することで実現している(1つの`.pre-commit-config.yaml`に複数の`repo:`を併記できる)。

### my-node-app-precommit-setup.zip

```
my-node-app/
├── .husky/pre-commit             ← lint-staged実行 + gitleaksチェックを追記
├── .husky/commit-msg             ← commit-msg-check.shを呼び出す(新規)
├── package.json                  ← husky/lint-staged設定込み
├── fetch_common_lint_rules.sh    ← 共通ESLint/Prettier/gitleaks/commit-msg-checkを取得(拡張)
├── gitlab-ci-lint-snippet.yml    ← .gitlab-ci.yml の lint stage抜粋(gitleaks + commit-msg-lint job込み)
└── SETUP_PRECOMMIT.md            ← セットアップ手順
```

`npm install` 時に `prepare` スクリプトが自動でhookを有効化する(Huskyの標準挙動)。Node.jsプロジェクトはpre-commitフレームワークを使わないため、共通スクリプト(`gitleaks.toml`、`commit-msg-check.sh`)を`fetch_common_lint_rules.sh`でローカルにコピーし、`.husky/`から直接呼び出す構成になっている。

---

## 4. 構築手順

### Step 0: 前提ツールのインストール(全プロジェクト共通)

`gitleaks-common`を使う全プロジェクトで、事前にgitleaks本体が必要になる。

```bash
# macOS
brew install gitleaks

# Linux
# https://github.com/gitleaks/gitleaks/releases から実行バイナリを取得し、PATHの通った場所に配置
```

CI環境(GitLab Runner)側のインストール方法は、7章の各`.gitlab-ci.yml`記載例を参照。

### Step 1: 共通テンプレートリポジトリをGitLabへ登録

1. GitLab上に `infra/pre-commit-templates` プロジェクトを新規作成する
2. `pre-commit-templates.zip` を展開し、中身をリポジトリ直下にpushする
3. バージョンタグを打つ

   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

### Step 2: SpringBoot + Vue プロジェクトへの適用

1. `my-springboot-vue-app-precommit-setup.zip` を展開し、`.pre-commit-config.yaml` と `SETUP_PRECOMMIT.md` を対象プロジェクトのリポジトリルートに配置する
2. `.pre-commit-config.yaml` 内の `repo:` のURLを、実際のGitLabインスタンスのパス(`infra/pre-commit-templates`)に置き換える
3. `backend/` に実際の `pom.xml`(checkstyle/spotbugsプラグイン設定込み)、`frontend/` に実際のVue/Viteプロジェクトを配置する
4. `SETUP_PRECOMMIT.md` の手順に従い、以下を実行する

   ```bash
   pip install pre-commit
   pre-commit install --hook-type pre-commit --hook-type commit-msg
   pre-commit run --all-files
   ```

   `.pre-commit-config.yaml`に`default_install_hook_types: [pre-commit, commit-msg]`を設定済みのため、`pre-commit install`のみ(オプション無し)でも両方のフックが有効になる。

### Step 3: Tomcat + Java プロジェクトへの適用

1. `my-tomcat-app-precommit-setup.zip` を展開し、`.pre-commit-config.yaml` をリポジトリルートに配置する
2. `pom.xml.snippet` の内容を、実プロジェクトの `pom.xml` の `<build><plugins>` 内に追記する
3. `gitlab-ci-lint-snippet.yml` の内容を、実プロジェクトの `.gitlab-ci.yml` の `lint` stageとしてマージする(gitleaksインストール手順を含む)
4. `pre-commit install` → `pre-commit run --all-files` で動作確認する(`checkstyle`, `spotbugs`, `gitleaks-common`, `commit-msg-check`の4hookが実行される)

### Step 4: Python プロジェクトへの適用

1. `my-python-app-precommit-setup.zip` を展開し、`.pre-commit-config.yaml` と `fetch_common_lint_rules.sh` をリポジトリルートに配置する
2. `fetch_common_lint_rules.sh` を実行し、共通の `pyproject.toml` を取得する

   ```bash
   ./fetch_common_lint_rules.sh
   ```

3. `pre-commit install` → `pre-commit run --all-files` で動作確認する(black/isort/flake8に加え、`gitleaks-common`, `commit-msg-check`も実行される)
4. `gitlab-ci-lint-snippet.yml` の内容を `.gitlab-ci.yml` にマージする(gitleaksインストール手順を含む)

### Step 5: Node.js プロジェクトへの適用

1. `my-node-app-precommit-setup.zip` を展開し、`.husky/`(`pre-commit`と`commit-msg`の2ファイル)、`package.json`、`fetch_common_lint_rules.sh` をリポジトリルートに配置する(既存の `package.json` がある場合は `devDependencies` と `lint-staged` セクションをマージする)
2. 依存パッケージをインストールする(Huskyの `prepare` スクリプトが自動でhookを設定する)

   ```bash
   npm install
   ```

3. 共通のESLint/Prettier/gitleaks/commit-msg-checkルールを取得する

   ```bash
   npm run fetch-common-lint-rules
   ```

   これにより `.eslintrc.common.cjs`, `.prettierrc.common.json`, `.gitleaks-common.toml`, `.husky-scripts/commit-msg-check.sh` がプロジェクトルートに配置される。

4. わざと規約違反のコードでコミットし、コミットが中止されることを確認する
5. わざと`type:`の無いコミットメッセージ(例: `git commit -m "テスト"`)でコミットし、`commit-msg`フックで中止されることを確認する
6. `gitlab-ci-lint-snippet.yml` の内容を `.gitlab-ci.yml` にマージする(gitleaksインストールと`commit-msg-lint` jobを含む)

### Step 6: 全プロジェクト共通の最終確認

各プロジェクトで以下を確認する。

- ローカルで `git commit` 実行時、意図的な規約違反コードでコミットが中止されること
- ダミーの機密情報(例: `AWS_SECRET_KEY = "AKIAxxxxxxxxxxxxxxxx"`)を含むコードでコミットし、`gitleaks-common`が検知して中止すること
- `type:`の無いコミットメッセージでコミットし、`commit-msg-check`が中止すること
- GitLab CI/CDの `lint` stageが、ローカルと同じ結果(エラー内容)を再現すること
- `pre-commit run --all-files`(またはNode.jsの場合は `npx eslint` / `npx prettier --check` / `gitleaks detect`)がCI上でも正しく実行されること

---

## 5. うまく動かない場合のチェックポイント

| 症状 | 確認箇所 |
|---|---|
| `checkstyle`/`spotbugs`が実行されない | `backend/pom.xml`(または対象プロジェクト直下の`pom.xml`)が存在するか、`files:`パターンが対象ファイルと一致しているか |
| `eslint-common`/`prettier-common`が実行されない | `frontend/package.json`が存在し、`npx eslint`/`npx prettier`がローカルで実行可能か |
| `repo`が見つからないエラー | `infra/pre-commit-templates`のURL・`rev`(タグ名)が正しいか、GitLabへのアクセス権があるか |
| Mavenがネットワークエラーになる | 社内プロキシ経由の設定(`~/.m2/settings.xml`)が必要な場合あり |
| Node.jsでhuskyのhookが効かない | `npm install`後に`.husky/pre-commit`・`.husky/commit-msg`に実行権限が付いているか、`package.json`の`prepare`スクリプトが実行されたか |
| `gitleaks-common`が「gitleaksコマンドが見つかりません」で失敗する | gitleaks本体がインストールされていない。4章Step 0の手順でインストールする |
| `gitleaks`が誤検知する(テストコードのダミー値等) | `configs/common/gitleaks.toml`の`[allowlist]`にパスパターンを追加するか、行末に`#gitleaks:allow`コメントを付与する |
| `commit-msg-check`が動かない(何もチェックされない) | `pre-commit install`が`commit-msg`フックタイプも含めて実行されているか(`default_install_hook_types`の設定、または`--hook-type commit-msg`オプション)を確認 |
| Node.jsで`commit-msg`フックが効かない | `.husky/commit-msg`に実行権限が付いているか、`fetch_common_lint_rules.sh`実行後に`.husky-scripts/commit-msg-check.sh`が存在するか確認 |

---

## 6. 共通ルール更新時の運用フロー

`infra/pre-commit-templates`はGitLab CI/CD Componentと同様、**バージョンタグ(rev)を各利用プロジェクトが個別に参照する**方式である。そのため、共通ルールを更新しても、各プロジェクト側で明示的に`rev`を上げない限り、既存の挙動は変わらない。ここでは更新作業の全体フローを詳しく説明する。

### 6.1 全体フロー図

```
[1] infra/pre-commit-templates でルール変更・動作確認
        ↓
[2] バージョンタグを打つ(例: v1.0.0 → v1.1.0)
        ↓
[3] 変更内容を周知する(破壊的変更かどうかを明記)
        ↓
[4] 各利用プロジェクトが任意のタイミングで rev を更新
        ↓
[5] 更新後、各プロジェクトでpre-commit実行 → 問題なければMR/コミット
        ↓
[6] 問題があれば rev を元に戻す(ロールバック)
```

### 6.2 Step 1: ルール変更と事前確認

`infra/pre-commit-templates`リポジトリ側で変更を行う。ルール変更後は、必ず**このリポジトリ自身のCI**(自己テスト)を通してから利用プロジェクトへ展開する。

```yaml
# infra/pre-commit-templates/.gitlab-ci.yml (自己テストの例)
stages:
  - self-test

test-checkstyle:
  stage: self-test
  image: maven:3.9-eclipse-temurin-17
  script:
    - cd sample-project  # 検証用のダミーJavaプロジェクトを用意しておく
    - bash ../scripts/java/checkstyle.sh
```

いきなり全プロジェクトに影響する変更を加える前に、**検証用のダミープロジェクトで動作確認する**ことを推奨する。

### 6.3 Step 2: バージョンタグの付け方

セマンティックバージョニング(`MAJOR.MINOR.PATCH`)に従い、変更の性質に応じてバージョンを使い分ける。

| 変更の種類 | 例 | バージョンの上げ方 |
|---|---|---|
| 破壊的変更(既存ルールが厳しくなり、既存コードがエラーになる可能性がある) | Checkstyleに新しい必須ルールを追加 | MAJOR(例: v1.x.x → v2.0.0) |
| 後方互換のある機能追加 | 新しいhook(id)を追加、既存ルールはそのまま | MINOR(例: v1.0.x → v1.1.0) |
| バグ修正・軽微な調整 | スクリプトの誤字修正、除外パターンの追加 | PATCH(例: v1.0.0 → v1.0.1) |

```bash
git tag v1.1.0
git push origin v1.1.0
```

### 6.4 Step 3: 変更内容の周知

タグを打っただけでは、各プロジェクトの担当者は変更に気づけない。`infra/pre-commit-templates`の`README.md`に**変更履歴(CHANGELOG)**を追記し、関係者へ周知する運用を推奨する。

```markdown
<!-- infra/pre-commit-templates/CHANGELOG.md -->
## v1.1.0 (2026-10-01)
- [MINOR] `eslint-common` に Vue3 の Composition API 向けルールを追加
- 影響: 既存コードへの影響なし。新規追加ルールのため必須対応は不要

## v2.0.0 (2026-11-01)
- [MAJOR] Checkstyle に行長制限(120文字)を追加
- 影響: 既存コードで120文字を超える箇所がある場合、`checkstyle` hookが失敗するようになる
- 対応: 各プロジェクトで `rev` を更新する前に、事前に `pre-commit run --all-files` で
  違反箇所を洗い出し、修正してから更新することを推奨
```

MAJORバージョンアップ(破壊的変更)の場合は、CHANGELOGへの記載に加えて、チームのチャットツールやメール等で個別に周知することを推奨する。

### 6.5 Step 4: 各利用プロジェクト側の更新方法

#### pre-commitフレームワーク採用プロジェクト(SpringBoot+Vue, Tomcat+Java, Python)

`.pre-commit-config.yaml`の`rev`を手動で書き換える方法と、コマンドで一括更新する方法がある。

```yaml
# 手動で書き換える場合
repos:
  - repo: https://gitlab.example.com/infra/pre-commit-templates
    rev: v1.1.0   # v1.0.0 から更新
```

```bash
# コマンドで自動更新する場合(pre-commit-templates以外に登録している
# 公式repoのrevも含めて、最新版に一括更新される点に注意)
pre-commit autoupdate

# 特定のrepoだけ対象にしたい場合
pre-commit autoupdate --repo https://gitlab.example.com/infra/pre-commit-templates
```

`autoupdate`は各`repo`の**最新タグ**に自動更新するため、意図せずメジャーバージョンアップまで取り込んでしまう可能性がある。破壊的変更を避けたい場合は、手動で狙ったバージョンに書き換える方が安全である。

#### Python/Node.jsプロジェクト(fetchスクリプト方式)

各`fetch_common_lint_rules.sh`内の`TEMPLATE_REV`を書き換えてから再実行する。

```bash
# fetch_common_lint_rules.sh 内
TEMPLATE_REV="v1.1.0"   # v1.0.0 から更新
```

```bash
./fetch_common_lint_rules.sh
```

### 6.6 Step 5: 更新後の確認

`rev`(または`TEMPLATE_REV`)を更新したら、必ず**更新前にローカルで動作確認**してからコミット・pushする。

```bash
pre-commit run --all-files
```

ここで大量のエラーが出た場合、CHANGELOGに記載されていた破壊的変更が実際に既存コードへ影響していることを意味する。この場合は次項のロールバックを検討するか、エラー内容に従ってコードを修正する。

### 6.7 Step 6: ロールバック(切り戻し)手順

更新後に問題が発覚した場合、`rev`(または`TEMPLATE_REV`)を**元のバージョンに戻すだけ**で切り戻せる。

```yaml
# .pre-commit-config.yaml を元に戻す
repos:
  - repo: https://gitlab.example.com/infra/pre-commit-templates
    rev: v1.0.0   # v1.1.0 から差し戻し
```

```bash
git add .pre-commit-config.yaml
git commit -m "revert: pre-commit-templatesをv1.0.0に切り戻し"
```

**重要**: `infra/pre-commit-templates`側で一度公開したタグ(`v1.1.0`等)は、他のプロジェクトが既に参照している可能性があるため、**タグ自体を削除・上書きしない**。問題があった場合は、修正版を`v1.1.1`のような新しいタグとして発行し、「`v1.1.0`は既知の問題があるため`v1.1.1`を使うこと」とCHANGELOGに明記する運用とする。

### 6.8 更新作業のチェックリスト(まとめ)

| チェック項目 | 内容 |
|---|---|
| □ | `infra/pre-commit-templates`側で変更後、自己テストが通ることを確認したか |
| □ | セマンティックバージョニングに従い、適切なタグ(MAJOR/MINOR/PATCH)を打ったか |
| □ | CHANGELOG.mdに変更内容と影響範囲を記載したか |
| □ | 破壊的変更(MAJOR)の場合、関係者へ個別に周知したか |
| □ | 各利用プロジェクトで`rev`更新後、`pre-commit run --all-files`で確認したか |
| □ | 問題があった場合の切り戻し手順(6.7節)を理解しているか |



## 7. GitLab CI/CDとの共通化

### 7.1 なぜCI側にも同じチェックを入れるのか

pre-commit(ローカル)とGitLab CI/CD(リモート)は、役割が異なる「二重の防衛線」である。

| 実行場所 | タイミング | 役割 |
|---|---|---|
| pre-commit(ローカル) | `git commit`実行時 | 開発者が「うっかりコミットしてしまう」のを未然に防ぐ(早期発見) |
| GitLab CI/CDの`lint` stage | push後、パイプライン実行時 | `pre-commit install`をし忘れた開発者や、`git commit --no-verify`でローカルチェックをスキップした場合の最終防衛線 |

両者が**同じルール(同じ`.pre-commit-config.yaml`や共通configファイル)を参照する**ことが重要である。ルールがローカルとCIでズレると、「ローカルでは通ったのにCIで落ちる」「その逆」が発生し、開発者の混乱と手戻りの原因になる。

### 7.2 全体のstages構成への位置づけ

以前検討した`stages`構成における `lint` は、この節で説明するpre-commit連携そのものにあたる。

```yaml
stages:
  - lint            # ← 本節で説明する内容(pre-commitの実行)
  - build
  - test
  - sonarqube
  - package
  - deploy-dev
  - smoke-test-dev
  - deploy-stg
  - smoke-test-stg
  - approval
  - deploy-prod
  - smoke-test-prod
```

`lint` stageは他のどの工程よりも早く、かつ低コストで異常を検知できる工程として最上流に置く。

### 7.3 プロジェクト別 `.gitlab-ci.yml` 記載例(lint stage完全版)

以下は各zipに含まれる `gitlab-ci-lint-snippet.yml` を、実際の `.gitlab-ci.yml` に組み込んだ完全形の例である。gitleaksを使う全プロジェクトで、CIランナー上にgitleaksバイナリをダウンロードする手順を`before_script`に追加している。

#### SpringBoot + Vue

```yaml
stages:
  - lint
  - build
  - test
  # ...(以降は既存設計を継続)

lint:
  stage: lint
  image: maven:3.9-eclipse-temurin-17
  before_script:
    # Java(Maven)は image に同梱済み。Node.jsを追加インストールする。
    - apt-get update && apt-get install -y python3-pip nodejs npm curl
    - pip3 install --break-system-packages pre-commit
    # gitleaksバイナリをインストール(gitleaks-commonフックの実行に必要)
    - curl -sSfL https://github.com/gitleaks/gitleaks/releases/download/v8.18.4/gitleaks_8.18.4_linux_x64.tar.gz | tar -xz -C /usr/local/bin gitleaks
  script:
    - pre-commit run --all-files
  cache:
    key: pre-commit-cache
    paths:
      - ~/.cache/pre-commit
```

`backend/`(Java)と`frontend/`(Vue)の両方を1つの`lint` jobでまとめてチェックする。`.pre-commit-config.yaml`の`files:`設定によって、変更のあった側だけ実際には実行される。`gitleaks-common`・`commit-msg-check`は`files:`の絞り込みがないため、常に実行される。

#### Tomcat + Java

```yaml
stages:
  - lint
  - build
  - test
  # ...(以降は既存設計を継続)

lint:
  stage: lint
  image: maven:3.9-eclipse-temurin-17
  before_script:
    - apt-get update && apt-get install -y python3-pip
    - pip3 install --break-system-packages pre-commit
    # gitleaksバイナリをインストール(gitleaks-commonフックの実行に必要)
    - curl -sSfL https://github.com/gitleaks/gitleaks/releases/download/v8.18.4/gitleaks_8.18.4_linux_x64.tar.gz | tar -xz -C /usr/local/bin gitleaks
  script:
    - pre-commit run --all-files
```

#### Python

```yaml
stages:
  - lint
  - build
  - test
  # ...(以降は既存設計を継続)

lint:
  stage: lint
  image: python:3.12-slim
  before_script:
    - pip install pre-commit
    - apt-get update && apt-get install -y curl
    - curl -sSfL https://github.com/gitleaks/gitleaks/releases/download/v8.18.4/gitleaks_8.18.4_linux_x64.tar.gz | tar -xz -C /usr/local/bin gitleaks
  script:
    - pre-commit run --all-files
```

#### Node.js(Husky運用のプロジェクト)

Node.jsは`pre-commit run`を使わないため、`eslint`/`prettier`/`gitleaks`を直接呼び出す`lint` jobと、コミットメッセージを検証する`commit-msg-lint` jobの2つに分けている。

```yaml
stages:
  - lint
  - build
  - test
  # ...(以降は既存設計を継続)

lint:
  stage: lint
  image: node:20-slim
  before_script:
    - npm ci
    - npm run fetch-common-lint-rules
    - apt-get update && apt-get install -y curl
    - curl -sSfL https://github.com/gitleaks/gitleaks/releases/download/v8.18.4/gitleaks_8.18.4_linux_x64.tar.gz | tar -xz -C /usr/local/bin gitleaks
  script:
    - npx eslint --config .eslintrc.common.cjs .
    - npx prettier --check --config .prettierrc.common.json .
    - gitleaks detect --source . --redact -v --config .gitleaks-common.toml

commit-msg-lint:
  stage: lint
  image: node:20-slim
  before_script:
    - npm run fetch-common-lint-rules
  script:
    # マージリクエスト内の全コミットメッセージをチェック
    - git log --pretty=format:%s "${CI_MERGE_REQUEST_DIFF_BASE_SHA}..${CI_COMMIT_SHA}" | while read -r msg; do
        echo "$msg" > /tmp/msg.txt;
        bash .husky-scripts/commit-msg-check.sh /tmp/msg.txt || exit 1;
      done
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
```

Node.jsのみ`pre-commit run`ではなく、`eslint`/`prettier`/`gitleaks`を直接呼び出す形になる点に注意。ローカルの`lint-staged`は差分ファイルのみが対象だが、CIでは`.`(カレントディレクトリ全体)を対象にすることで、pushされた全ファイルを漏れなくチェックする。`commit-msg-lint`は、ローカルの`.husky/commit-msg`(コミット単位でのチェック)とは異なり、**マージリクエストにまとめて含まれる全コミットのメッセージを一括検証**する点が異なる。

### 7.4 実行時間短縮のオプション(マージリクエスト時は差分のみチェック)

`pre-commit run --all-files`は全ファイルを毎回チェックするため、リポジトリが大きくなると時間がかかる。マージリクエスト時は差分ファイルのみに絞ることで高速化できる。

```yaml
lint:
  stage: lint
  image: python:3.12-slim
  before_script:
    - pip install pre-commit
  script:
    - |
      if [ "$CI_PIPELINE_SOURCE" == "merge_request_event" ]; then
        pre-commit run --from-ref origin/$CI_MERGE_REQUEST_TARGET_BRANCH_NAME --to-ref HEAD
      else
        pre-commit run --all-files
      fi
```

マージリクエスト時は差分のみ、`main`ブランチへの直接pushやスケジュール実行時は全件チェック、という使い分けができる。

### 7.5 GitLab CI/CD Component化との連携(発展形)

以前検討した「GitLab CI/CD Component」の仕組みを使うと、`lint` job自体もテンプレート化できる。`infra/gitlab-ci-templates`(CI用の共通リポジトリ)側に以下のようなComponentを用意する。

```yaml
# infra/gitlab-ci-templates/templates/pre-commit-lint.yml
spec:
  inputs:
    project_type:
      type: string
      options: ["java", "java-vue", "python", "node"]
    pre_commit_rev:
      type: string
      default: "v1.0.0"
---
lint:
  stage: lint
  image: $[[ inputs.project_type == "python" && "python:3.12-slim" || inputs.project_type == "node" && "node:20-slim" || "maven:3.9-eclipse-temurin-17" ]]
  before_script:
    - |
      if [ "$[[ inputs.project_type ]]" == "node" ]; then
        npm ci
        npm run fetch-common-lint-rules
      else
        apt-get update && apt-get install -y python3-pip
        pip3 install --break-system-packages pre-commit
      fi
  script:
    - |
      if [ "$[[ inputs.project_type ]]" == "node" ]; then
        npx eslint --config .eslintrc.common.cjs .
        npx prettier --check --config .prettierrc.common.json .
      else
        pre-commit run --all-files
      fi
```

各プロジェクトの`.gitlab-ci.yml`は、以下のように1行のincludeだけで済むようになる。

```yaml
# my-springboot-vue-app/.gitlab-ci.yml
include:
  - component: gitlab.example.com/infra/gitlab-ci-templates/pre-commit-lint@1.0.0
    inputs:
      project_type: "java-vue"

stages:
  - lint
  - build
  - test
  # ...
```

```yaml
# my-python-app/.gitlab-ci.yml
include:
  - component: gitlab.example.com/infra/gitlab-ci-templates/pre-commit-lint@1.0.0
    inputs:
      project_type: "python"
```

この形にすると、`lint` jobの中身を変更したい場合も`infra/gitlab-ci-templates`側を1回直すだけで、全プロジェクトに反映される。**pre-commitのルール(`infra/pre-commit-templates`)とCI実行方法(`infra/gitlab-ci-templates`)を、それぞれ別リポジトリとして役割分担して管理する**構成が最終形として理想的である。

```
infra/pre-commit-templates   ← 「何をチェックするか」のルールを管理
infra/gitlab-ci-templates    ← 「どうやってCI上で実行するか」のjob定義を管理
```

### 7.6 補足: pre-commitのキャッシュについて

`pip install pre-commit`後、初回実行時にpre-commitは各hookの実行環境(Python仮想環境等)を`~/.cache/pre-commit`配下に構築する。GitLab CI/CDの`cache:`機能でこのディレクトリをキャッシュしておくと、2回目以降のパイプライン実行が高速化される。

```yaml
lint:
  stage: lint
  image: python:3.12-slim
  before_script:
    - pip install pre-commit
  script:
    - pre-commit run --all-files
  cache:
    key: pre-commit-${CI_PROJECT_ID}
    paths:
      - ~/.cache/pre-commit
```

ただし、本構成の`checkstyle`/`spotbugs`/`eslint`/`prettier`は`language: script`(実行環境をそのまま使う)で定義しているため、pre-commit自体の仮想環境構築コストは小さい。効果が大きいのは、Python版で`black`/`flake8`等を**pre-commit公式repo経由**(`language: python`)で使っている場合である。

---

## 8. 日常運用(実行方法・結果の見方・スキップ方法)

構築が完了した後、開発者が日々どう使うかをまとめる。

### 8.1 通常の実行(自動)

`pre-commit install`(またはNode.jsの場合は`npm install`によるHusky設定)が済んでいれば、`git commit`のたびに自動でチェックが走る。開発者が意識して何かコマンドを打つ必要はない。

```bash
git add .
git commit -m "feat: ユーザー一覧APIを追加"
```

このとき、内部的には以下が実行されている。

```
git commit
  → .git/hooks/pre-commit が起動
    → pre-commitフレームワーク(またはHusky)が .pre-commit-config.yaml
      (またはlint-staged設定)に従って各hookを実行
      → 全hookが成功 → コミット成立
      → いずれかのhookが失敗 → コミット中止、エラー内容が表示される
```

### 8.2 手動での実行(コミット前に事前確認したい場合)

コミットする前に、いま変更している内容が問題ないか確認したいことがある。以下のコマンドで、実際にコミットせずにチェックだけ実行できる。

#### pre-commitフレームワーク採用プロジェクト(SpringBoot+Vue, Tomcat+Java, Python)

```bash
# ステージング済み(git add済み)のファイルのみチェック
pre-commit run

# リポジトリ内の全ファイルをチェック(初回導入時や、設定変更後の確認に使う)
pre-commit run --all-files

# 特定のhookだけ実行したい場合(hook idを指定)
pre-commit run checkstyle
pre-commit run eslint-common

# 特定のファイルだけを対象にチェックしたい場合
pre-commit run --files backend/src/main/java/com/example/UserController.java
```

#### Node.js(Husky + lint-staged)プロジェクト

lint-stagedはコミット時にのみ動作する設計のため、手動で「コミット前に試す」場合は、対象ツールを直接呼び出す。

```bash
# 変更ファイルに関わらず全体をチェック
npx eslint --config .eslintrc.common.cjs .
npx prettier --check --config .prettierrc.common.json .

# 自動修正もかけたい場合
npx eslint --fix --config .eslintrc.common.cjs .
npx prettier --write --config .prettierrc.common.json .
```

### 8.3 結果の見方

#### 成功時の表示例(pre-commitフレームワーク)

```
Checkstyle (backend)................................................Passed
SpotBugs (backend)...................................................Passed
ESLint (frontend)....................................................Passed
Prettier (frontend)..................................................Passed
```

すべて `Passed` であれば、コミットはそのまま成立する。

#### 失敗時の表示例

```
Checkstyle (backend)................................................Failed
- hook id: checkstyle
- exit code: 1

[ERROR] UserController.java:42: Line is longer than 120 characters.
[ERROR] UserController.java:58: Unused import - java.util.List.
```

`Failed`になったhookがあると、**コミット自体が成立せず中止される**。表示されたエラー内容(ファイル名・行番号・違反内容)を確認し、修正してから再度`git add` → `git commit`をやり直す。

#### 自動修正されるケース(ESLint/Prettier)

ESLintやPrettierは、多くの違反を**自動修正**する。この場合、以下のような表示になる。

```
ESLint (frontend)....................................................Failed
- hook id: eslint-common
- files were modified by this hook

frontend/src/components/UserList.vue
```

「`Failed`だがファイルが自動修正された」という状態である。**この場合、修正されたファイルはまだステージング(`git add`)されていない**ため、以下の手順で再度コミットし直す必要がある。

```bash
git add .              # 自動修正された内容を再度ステージング
git commit -m "feat: ユーザー一覧APIを追加"   # 再度コミット(今度は成功するはず)
```

これはpre-commitの標準的な仕様であり、「自動修正はしたが、修正後の内容を本当にコミットしてよいか」を開発者に確認させるための安全策である。

#### gitleaksが機密情報を検知した場合の表示例

```
gitleaks (機密情報検出).............................................Failed
- hook id: gitleaks-common
- exit code: 1

Finding:     AWS_SECRET_KEY = "AKIA****************"
Secret:      AKIA****************
RuleID:      aws-access-token
File:        backend/src/main/resources/application.properties
Line:        12
```

このケースは**自動修正されない**。表示されたファイル・行を確認し、該当の機密情報を環境変数やSecret管理ツール(GitLab CI/CD Variables等)に置き換えてから、再度コミットする。

**注意**: 一度コミット履歴に混入した機密情報は、`git commit`を中止しても**ステージング前のファイル自体には残っている**。誤って別の方法(`git commit --no-verify`等)でコミットしてしまった場合は、単なるファイル修正だけでなく、**該当の認証情報自体を失効・再発行する**対応が必要になる。

#### commit-msg-checkが失敗した場合の表示例

```
$ git commit -m "ユーザー一覧APIを追加"

----------------------------------------------------------------------
[commit-msg-check] コミットメッセージがConventional Commits形式ではありません。

  現在のメッセージ : ユーザー一覧APIを追加

  期待する形式     : <type>(<scope>): <subject>
  例               : feat(user): ユーザー一覧APIを追加

  使用可能なtype   : feat, fix, docs, style, refactor, perf, test, chore, build, ci, revert
----------------------------------------------------------------------
```

この場合、`-m`オプションの内容を修正して再度コミットする。

```bash
git commit -m "feat: ユーザー一覧APIを追加"
```

### 8.4 コミットが失敗し続ける場合の切り分け

| 状況 | 対応 |
|---|---|
| エラーメッセージ通りに直しても`Failed`のまま | `git status`で修正ファイルが正しく`git add`されているか確認 |
| Mavenのビルド自体が失敗している(コンパイルエラー) | `checkstyle`/`spotbugs`以前の問題。まず`mvn compile`が通ることを確認 |
| ESLintが「設定ファイルが見つからない」と言う | `.eslintrc.common.cjs`のパスが正しいか(共通repoから取得済みか)を確認 |
| `gitleaks-common`が「gitleaksコマンドが見つかりません」と言う | 4章Step 0の手順でgitleaks本体をインストールする |
| `commit-msg-check`が意図せず失敗する(正当なメッセージなのに) | マージコミットや`git revert`直後のメッセージは自動的に許可される設計だが、それ以外の特殊な書き方をしている場合は`scripts/common/commit-msg-check.sh`内の正規表現(`PATTERN`)を確認する |

### 8.5 pre-commitをスキップする方法(緊急時・例外対応)

どうしても一時的にチェックをスキップしたい場合(例: 緊急のホットフィックスで、次のコミットで必ず直す前提の暫定対応)のための操作方法。**乱用すると本仕組みの意味がなくなるため、後述の運用ルールを参照した上で使うこと。**

**特に`gitleaks-common`のスキップは慎重に**: Lint系のスキップは「後で直せばよい」で済むが、機密情報のpushは**リモートリポジトリの履歴に残ってしまう**ため、スキップしたまま気づかずpushすると被害が大きい。緊急時以外はスキップしないことを強く推奨する。

#### 全hookをスキップ

```bash
git commit -m "hotfix: 緊急対応" --no-verify
```

`--no-verify`(`-n`も可)を付けると、pre-commit/Huskyのフック自体が起動しない。**`gitleaks-common`と`commit-msg-check`も含めて全てスキップされる**点に注意。

#### 特定のhookだけスキップ(pre-commitフレームワーク)

`SKIP`環境変数に、スキップしたいhook idをカンマ区切りで指定する。

```bash
SKIP=checkstyle,spotbugs git commit -m "feat: 一時的にcheckstyleのみスキップ"

# commit-msg-checkのみスキップしたい場合(コミットメッセージの制約を一時的に外したい場合)
SKIP=commit-msg-check git commit -m "wip: 作業中"
```

#### Node.js(Husky)でスキップ

```bash
HUSKY=0 git commit -m "hotfix: 緊急対応"
```

または`--no-verify`でも同様にスキップできる。Node.jsの場合、`SKIP`環境変数によるhook単位の指定はできない(Husky自体にその機能がないため)。特定のチェックだけ外したい場合は、`.husky/pre-commit`の該当行を一時的にコメントアウトする必要がある。

#### 特定のファイルを恒久的にチェック対象から除外したい場合

一時的なスキップではなく、恒久的に対象外にしたいファイル(自動生成コード等)がある場合は、`.pre-commit-config.yaml`側に`exclude`を設定する。

```yaml
repos:
  - repo: https://gitlab.example.com/infra/pre-commit-templates
    rev: v1.0.0
    hooks:
      - id: eslint-common
        files: ^frontend/.*\.(js|ts|vue)$
        exclude: ^frontend/src/generated/   # 自動生成ディレクトリを除外
```

gitleaksの場合は、`.pre-commit-config.yaml`の`exclude`ではなく、共通設定`configs/common/gitleaks.toml`側の`[allowlist]`にパスパターンを追加する(3章参照)。プロジェクト固有の除外をしたい場合は、`GITLEAKS_CONFIG`環境変数でプロジェクト独自の設定ファイルを指定することもできる。

### 8.6 スキップ運用に関するルール(推奨)

pre-commitはあくまで「ローカルでの一次防衛」であり、GitLab CI/CDの`lint` stageが「最終防衛線」である(4章・7章参照)。そのため、以下の運用を推奨する。

- `--no-verify`でスキップしても、**CI側の`lint` stageは必ず実行される**ため、スキップしたコードに問題があればマージリクエスト上で検知される
- `--no-verify`を使った場合は、コミットメッセージやMRの説明に理由を明記する(例: `[skip-precommit] 理由: xxx`)ことをチームルールとして推奨する
- `SKIP`環境変数での恒久的な運用は避け、本当に対象外にすべきファイルは`.pre-commit-config.yaml`の`exclude`(またはgitleaksの`[allowlist]`)で明示的に管理する
- **`gitleaks-common`のスキップは原則禁止**とし、どうしても必要な場合はチームリーダー等の承認を得るルールにすることを推奨する(機密情報漏洩は事後対応のコストが非常に高いため)



## 9. 未確定・今後の検討事項

- Node.js単体プロジェクトについても、将来的に共通ESLint設定をnpmパッケージとして配布する方式へ移行するか検討の余地がある
- 7.5節で示した`infra/gitlab-ci-templates`側の`pre-commit-lint` Componentは設計イメージであり、実際に作成・検証は未実施
- `infra/pre-commit-templates`(ルール管理)と`infra/gitlab-ci-templates`(CI実行管理)の2リポジトリ運用について、チーム内での責任分担(誰がどちらを更新するか)を決める必要がある
- gitleaksバイナリのバージョン(`v8.18.4`)は各`.gitlab-ci.yml`スニペットにハードコードしているため、バージョン更新時は全プロジェクトの記載を個別に直す必要がある。将来的にはCIランナー側にgitleaksを同梱したDockerイメージを別途用意し、`image:`切り替えだけで済む形に改善する余地がある
- `commit-msg-check.sh`の正規表現(Conventional Commits形式)がプロジェクトの実態に合わない場合(例: 日本語のtypeを使いたい等)、共通ルールとして固定するか、プロジェクトごとに`COMMIT_MSG_PATTERN`のような環境変数で上書き可能にするかは今後の検討事項
- 過去のコミット履歴に既に機密情報が混入していないか、`gitleaks detect`(historyスキャンモード)でリポジトリ全体を一度棚卸しすることを推奨するが、実施タイミング・対応フローは未確定
