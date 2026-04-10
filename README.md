# nix-templates

> [!CAUTION]
> このリポジトリのルートにあるファイル(`flake.nix`, `.github/workflows/`など)は、
> テンプレートを管理するためのファイルです。
> これ自体はテンプレートではないので、
> コピーしたり参考にしてはいけません。
> 実際のテンプレートは`templates/`ディレクトリ以下にあります。

Nix flake templates.

## Templates

### basic

treefmt, CI, devShellなどを含む基本的なNix flakeテンプレート。

```zsh
nix flake init -t 'github:ncaq/nix-templates#basic'
```

### github-action

GitHub Actionプロジェクト向けのテンプレート。
basicの内容に加え、composite action, VERSIONベースのリリースワークフローを含みます。

```zsh
nix flake init -t 'github:ncaq/nix-templates#github-action'
```

### typescript

TypeScriptプロジェクト向けの基本テンプレート。
basicの内容に加え、npm, vitest, ESLint, Prettierを含みます。

```zsh
nix flake init -t 'github:ncaq/nix-templates#typescript'
```

## Development

### テンプレートファイルの同期

`templates/`以下の各テンプレートには、
ルートリポジトリと共通のファイル(`.editorconfig`, `.github/actions/`など)が含まれています。
これらはルートのファイルのコピーであり、
`checks.template-sync`で差分がないことを検証しています。

共通ファイルを更新した場合は、
以下のコマンドでテンプレートに反映してください。

```zsh
nix run '.#sync-template-files'
```

テンプレート固有のファイル(`flake.nix`, `README.md`など)は同期対象外です。
