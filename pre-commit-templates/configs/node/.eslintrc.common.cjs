// 全社共通のESLintルール雛形 (Vue3 + TypeScript想定)
module.exports = {
  root: true,
  env: {
    browser: true,
    es2022: true,
    node: true,
  },
  extends: [
    'eslint:recommended',
    'plugin:vue/vue3-recommended',
    'plugin:@typescript-eslint/recommended',
    'prettier', // Prettierと競合するルールを無効化
  ],
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
  },
  rules: {
    // プロジェクト共通の上書きルールがあればここに追加
    'vue/multi-word-component-names': 'off',
    'no-console': 'warn',
  },
}
