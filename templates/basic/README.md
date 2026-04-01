# Project Name

## Setup

```console
direnv allow
```

## Format

```console
nix fmt
```

## Check

```console
nix-fast-build --option eval-cache false --no-link --skip-cached
```

`nix-fast-build`の以下の、

``` console
--no-nom              Don't use nix-output-monitor to print build output (default: false)
```

`--no-nom`オプションはCI環境やLLMエージェント経由での起動など、
ターミナル制御が貧弱な環境でシンプルなビルドログを得るために使うオプションなので、
ユーザがローカルでビルドする際には通常は必要ありません。
