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
          typescript = {
            path = ./templates/typescript;
            description = "TypeScript project template with npm, vitest, ESLint, and Prettier";
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
            "typescript"
          ];

          # テンプレート間で共通のファイル(各テンプレートに同期される)
          syncFiles = [
            ".dir-locals.el"
            ".editorconfig"
            ".editorconfig-checker.json"
            ".envrc"
            ".github/actions/setup-nix/action.yml"
            ".github/git-commit-instructions.md"
            ".github/release.yml"
            ".marksman.toml"
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
              # CLAUDE.mdシンボリックリンクの確認・作成
              ${pkgs.lib.concatMapStringsSep "\n" (dir: ''
                if [ ! -L "$root/templates/${dir}/CLAUDE.md" ]; then
                  ln -sf .github/copilot-instructions.md "$root/templates/${dir}/CLAUDE.md"
                fi
              '') templateDirs}
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
              typos.enable = true;
              zizmor.enable = true;

              statix = {
                enable = true;
                disabled-lints = [ "eta_reduction" ];
              };
            };
            settings.formatter = {
              editorconfig-checker = {
                command = pkgs.lib.getExe (
                  pkgs.writeShellApplication {
                    name = "editorconfig-checker-wrapper";
                    runtimeInputs = [ pkgs.editorconfig-checker ];
                    text = ''
                      editorconfig-checker "$@"
                    '';
                  }
                );
                includes = [ "*" ];
              };
            };
          };
          packages = {
            # flake.lockの管理バージョンをre-exportすることで安定した利用を促進。
            inherit (pkgs)
              nix-fast-build
              ;
            inherit sync-template-files sync-commit;
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
              # CLAUDE.mdシンボリックリンクの検証
              ${pkgs.lib.concatMapStringsSep "\n" (dir: ''
                target=$(readlink "${./templates}/${dir}/CLAUDE.md")
                if [ "$target" != ".github/copilot-instructions.md" ]; then
                  echo "templates/${dir}/CLAUDE.md symlink target is wrong: $target"
                  echo "Expected: .github/copilot-instructions.md"
                  exit 1
                fi
              '') templateDirs}
              touch $out
            '';
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
              nix-fast-build
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
