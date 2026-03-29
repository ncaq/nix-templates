# nix-templates

Nix flake templates.

## Usage

```zsh
nix flake init -t 'github:ncaq/nix-templates#basic'
```

## Templates

### basic

treefmt, CI, devShellなどを含む基本的なNix flakeテンプレート。

### typescript

TypeScriptプロジェクト向けの基本テンプレート。
basicの内容に加え、npm, vitest, ESLint, Prettierを含みます。

```zsh
nix flake init -t 'github:ncaq/nix-templates#typescript'
```

## テンプレートファイルの同期

`templates/`以下の各テンプレートには、
ルートリポジトリと共通のファイル(`.editorconfig`, `.github/actions/`, `.gitignore`など)が含まれています。
これらはルートのファイルのコピーであり、
`checks.template-sync`で差分がないことを検証しています。

共通ファイルを更新した場合は、
以下のコマンドでテンプレートに反映してください。

```zsh
nix run '.#sync-template-files'
```

テンプレート固有のファイル(`flake.nix`, `README.md`, `.github/workflows/push.yml`)は同期対象外です。
