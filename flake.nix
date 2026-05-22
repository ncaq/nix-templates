{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
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

      flake = {
        templates = {
          basic = {
            path = ./templates/basic;
            description = "Basic Nix flake template with treefmt, CI, and dev tools";
          };
          github-action = {
            path = ./templates/github-action;
            description = "GitHub Action template with composite action";
          };
          haskell-himari = {
            path = ./templates/haskell-himari;
            description = "Haskell project template using himari prelude";
          };
          typescript = {
            path = ./templates/typescript;
            description = "TypeScript project template using npm";
          };
        };
      };

      perSystem =
        {
          pkgs,
          ...
        }:
        let
          templateDirs = [
            "basic"
            "github-action"
            "haskell-himari"
            "typescript"
          ];

          # テンプレート間で共通のファイル(各テンプレートに同期される)
          syncFiles = [
            ".dir-locals.el"
            ".editorconfig"
            ".editorconfig-checker.json"
            ".envrc"
            ".github/git-commit-instructions.md"
            ".github/release.yml"
            ".github/workflows/kyosei.yml"
            ".marksman.toml"
            "_typos.toml"
            "renovate.json"
            "statix.toml"
          ];

          # 各テンプレートに作成するシンボリックリンク(target -> linkName)
          syncSymlink = [
            {
              target = ".github/copilot-instructions.md";
              linkName = "AGENTS.md";
            }
            {
              target = ".github/copilot-instructions.md";
              linkName = "CLAUDE.md";
            }
          ];

          sync-template-files = pkgs.writeShellApplication {
            name = "sync-template-files";
            runtimeInputs = with pkgs; [
              coreutils
            ];
            text = ''
              root="''${1:-.}"
              ${pkgs.lib.concatMapStringsSep "\n" (
                dir:
                pkgs.lib.concatMapStringsSep "\n" (f: ''
                  mkdir -p "$root/templates/${dir}/$(dirname "${f}")"
                  cp "$root/${f}" "$root/templates/${dir}/${f}"
                '') syncFiles
              ) templateDirs}
              # シンボリックリンクの確認・作成
              ${pkgs.lib.concatMapStringsSep "\n" (
                dir:
                pkgs.lib.concatMapStringsSep "\n" (
                  { target, linkName }:
                  ''
                    ln -sf ${target} "$root/templates/${dir}/${linkName}"
                  ''
                ) syncSymlink
              ) templateDirs}
              echo "Template files synced."
            '';
          };

          sync-commit = pkgs.writeShellApplication {
            name = "sync-commit";
            runtimeInputs = with pkgs; [
              coreutils
              git
              sync-template-files
            ];
            text = ''
              sync-template-files
              git add -A
              git commit -m "chore: \`nix run '.#sync-template-files'\`"
            '';
          };
        in
        {
          treefmt.config = {
            projectRootFile = "flake.nix";
            programs = {
              actionlint.enable = true;
              deadnix.enable = true;
              nixfmt.enable = true;
              prettier.enable = true;
              shellcheck.enable = true;
              shfmt.enable = true;
              statix.enable = true;
              typos.enable = true;
              zizmor.enable = true;
            };
            settings.formatter = {
              editorconfig-checker = {
                command = pkgs.editorconfig-checker;
                includes = [ "*" ];
              };
              zizmor = {
                options = [ "--pedantic" ];
                includes = [
                  ".github/*.yml"
                  "templates/*/.github/*.yml"
                  "templates/*/action.yml"
                ];
              };
            };
          };

          checks = {
            template-sync = pkgs.runCommand "template-sync-check" { } ''
              ${pkgs.lib.concatMapStringsSep "\n" (
                dir:
                pkgs.lib.concatMapStringsSep "\n" (f: ''
                  diff "${./.}/${f}" "${./templates}/${dir}/${f}" || {
                    echo "File out of sync: templates/${dir}/${f}"
                    echo "Run: nix run .#sync-template-files"
                    exit 1
                  }
                '') syncFiles
              ) templateDirs}
              # シンボリックリンクの検証
              ${pkgs.lib.concatMapStringsSep "\n" (
                dir:
                pkgs.lib.concatMapStringsSep "\n" (
                  { target, linkName }:
                  ''
                    actual=$(readlink "${./templates}/${dir}/${linkName}")
                    if [ "$actual" != "${target}" ]; then
                      echo "templates/${dir}/${linkName} symlink target is wrong: $actual"
                      echo "Expected: ${target}"
                      exit 1
                    fi
                  ''
                ) syncSymlink
              ) templateDirs}
              touch $out
            '';
          };

          packages = {
            # flake.lockの管理バージョンをre-exportすることで安定した利用を促進。
            inherit (pkgs)
              nix-fast-build
              ;
            inherit sync-template-files sync-commit;
          };

          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [
              # treefmtで指定したプログラムの単体版。
              actionlint
              deadnix
              editorconfig-checker
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
