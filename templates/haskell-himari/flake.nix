{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    himari-src = {
      url = "github:ncaq/himari/v1.1.2.2";
      flake = false;
    };
  };

  outputs =
    inputs@{
      flake-parts,
      treefmt-nix,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        treefmt-nix.flakeModule
      ];

      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];

      perSystem =
        {
          pkgs,
          lib,
          ...
        }:
        let
          # `cabal.project`の`with-compiler`で指定したGHCバージョンを尊重し、
          # 対応するnixpkgsのパッケージセットを選択します。
          # こうすることでGHCバージョンの管理が`cabal.project`に一元化されます。
          cabalHaskellGhcVersion =
            let
              m = builtins.match ".*with-compiler:[[:space:]]*ghc-([0-9.]+).*" (
                builtins.readFile ./cabal.project
              );
            in
            if m == null then throw "cabal.projectにwith-compilerが見つかりません" else builtins.head m;
          # このプロジェクトで使うHaskellのパッケージセット。
          haskellPackages =
            pkgs.haskell.packages."ghc${builtins.replaceStrings [ "." ] [ "" ] cabalHaskellGhcVersion}".override
              {
                overrides = hself: _hsuper: {
                  # himariはnixpkgsでbroken指定を受けています。
                  # brokenの理由はテストのインフラとnixpkgsの相性の問題なので、
                  # 利用すること自体には問題はありません。
                  # 問題をhimari側で解決して、
                  # brokenが解除されたらこのoverrideは削除する予定です。
                  himari = pkgs.haskell.lib.compose.doJailbreak (hself.callCabal2nix "himari" inputs.himari-src { });
                };
              };
          haskellProject = haskellPackages.callCabal2nix "haskell-project" ./. { };
        in
        {
          treefmt.config = {
            projectRootFile = "flake.nix";
            programs = {
              actionlint.enable = true;
              deadnix.enable = true;
              fourmolu.enable = true;
              hlint.enable = true;
              nixfmt.enable = true;
              prettier.enable = true;
              shellcheck.enable = true;
              shfmt.enable = true;
              statix.enable = true;
              typos.enable = true;
              zizmor.enable = true;
            };
            settings.formatter = {
              # cabal-gildのモジュール自動発見機能に対応するため、
              # Haskellソースファイルの変更も検知してcabal-gildを実行します。
              # treefmt-nixの上流では、
              # 変更されたファイルだけを修正したいと言われてマージされていませんが、
              # ローカルで使う分には問題ありません。
              # [cabal-gild discover module](https://github.com/numtide/treefmt-nix/pull/384)
              cabal-gild = {
                command = lib.getExe (
                  pkgs.writeShellApplication {
                    name = "cabal-gild-wrapper";
                    runtimeInputs = with pkgs; [
                      git
                      haskellPackages.cabal-gild
                      parallel
                    ];
                    text = ''
                      git ls-files -z "*.cabal" | parallel --null "cabal-gild --io {}"
                    '';
                  }
                );
                includes = [
                  "*.cabal"
                  # Haskellソースファイルの変更を検知するために含める
                  "*.hs"
                  "*.lhs"
                  "*.hsc"
                  "*.chs"
                  "*.hsig"
                  "*.lhsig"
                ];
              };
              editorconfig-checker = {
                command = pkgs.editorconfig-checker;
                includes = [ "*" ];
              };
              zizmor.options = [ "--pedantic" ];
            };
          };

          checks = {
            haskell-project = pkgs.haskell.lib.compose.appendConfigureFlags [
              "--ghc-options=-Werror"
            ] haskellProject;
          };

          packages = {
            default = haskellProject;
            # flake.lockの管理バージョンをre-exportすることで安定した利用を促進。
            inherit (pkgs)
              nix-fast-build
              ;
          };

          devShells.default = haskellPackages.shellFor {
            packages = _p: [ haskellProject ];
            nativeBuildInputs = with pkgs; [
              # treefmtで指定したプログラムの単体版。
              actionlint
              deadnix
              editorconfig-checker
              fourmolu
              haskellPackages.cabal-gild
              hlint
              nixfmt
              prettier
              shellcheck
              shfmt
              statix
              typos
              zizmor

              # nixの関連ツール。
              nil
              nix-fast-build

              # GitHub関連ツール。
              gh

              # Haskell関連ツール。
              cabal-install
              haskellPackages.haskell-language-server
            ];
          };
        };
    };

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org/"
      "https://niks3-public.ncaq.net/"
      "https://ncaq.cachix.org/"
      "https://nix-community.cachix.org/"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "niks3-public.ncaq.net-1:e/B9GomqDchMBmx3IW/TMQDF8sjUCQzEofKhpehXl04="
      "ncaq.cachix.org-1:XF346GXI2n77SB5Yzqwhdfo7r0nFcZBaHsiiMOEljiE="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
}
