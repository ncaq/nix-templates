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

composite actionのスケルトンなどを含みます。

```zsh
nix flake init -t 'github:ncaq/nix-templates#github-action'
```

### haskell-himari

Haskellプロジェクト向けテンプレート。

[himari](https://hackage.haskell.org/package/himari)プレリュードを使用します。

Haskellビルドインフラでの開発環境のセットアップが含まれます。

```zsh
nix flake init -t 'github:ncaq/nix-templates#haskell-himari'
```

### haskell-nix-himari

Haskellプロジェクト向けテンプレート。

[himari](https://hackage.haskell.org/package/himari)プレリュードを使用します。

環境構築に[haskell.nix](https://github.com/input-output-hk/haskell.nix)を使用します。

haskell-himariはnixpkgsのHaskellパッケージセットを使うのに対し、
こちらはhaskell.nixを使うため重量級ですが、
Cabalソルバーによる柔軟な依存解決などの恩恵を受けられます。

```zsh
nix flake init -t 'github:ncaq/nix-templates#haskell-nix-himari'
```

### typescript

TypeScriptプロジェクト向けの基本テンプレート。

npmベースの開発環境が含まれます。

```zsh
nix flake init -t 'github:ncaq/nix-templates#typescript'
```

## Development

### テンプレートファイルの同期

`templates/`以下の各テンプレートには、
ルートリポジトリと共通のファイル(`.editorconfig`, `.github/workflows/kyosei.yml`など)が含まれています。
これらはルートのファイルのコピーであり、
`checks.template-sync`で差分がないことを検証しています。

共通ファイルを更新した場合は、
以下のコマンドでテンプレートに反映してください。

```zsh
nix run '.#sync-template-files'
```

テンプレート固有のファイル(`flake.nix`, `README.md`など)は同期対象外です。
