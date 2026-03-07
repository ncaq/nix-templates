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
        };
      };

      perSystem =
        {
          pkgs,
          ...
        }:
        let
          syncFiles = [
            ".claude/settings.json"
            ".dir-locals.el"
            ".editorconfig"
            ".editorconfig-checker.json"
            ".envrc"
            ".github/actions/setup-nix/action.yml"
            ".github/copilot-instructions.md"
            ".github/dependabot.yml"
            ".github/git-commit-instructions.md"
            ".github/release.yml"
            ".gitignore"
            ".marksman.toml"
          ];
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
            sync-template-files = pkgs.writeShellApplication {
              name = "sync-template-files";
              runtimeInputs = with pkgs; [
                coreutils
                rsync
              ];
              text = ''
                root="''${1:-.}"
                ${pkgs.lib.concatMapStringsSep "\n" (f: ''
                  mkdir -p "$root/templates/basic/$(dirname "${f}")"
                  cp "$root/${f}" "$root/templates/basic/${f}"
                '') syncFiles}
                # CLAUDE.mdシンボリックリンクの確認・作成
                if [ ! -L "$root/templates/basic/CLAUDE.md" ]; then
                  ln -sf .github/copilot-instructions.md "$root/templates/basic/CLAUDE.md"
                fi
                echo "Template files synced."
              '';
            };
          };
          checks = {
            template-sync = pkgs.runCommand "template-sync-check" { } ''
              ${pkgs.lib.concatMapStringsSep "\n" (f: ''
                diff "${./.}/${f}" "${./templates/basic}/${f}" || {
                  echo "File out of sync: ${f}"
                  echo "Run: nix run .#sync-template-files"
                  exit 1
                }
              '') syncFiles}
              # CLAUDE.mdシンボリックリンクの検証
              target=$(readlink "${./templates/basic}/CLAUDE.md")
              if [ "$target" != ".github/copilot-instructions.md" ]; then
                echo "CLAUDE.md symlink target is wrong: $target"
                echo "Expected: .github/copilot-instructions.md"
                exit 1
              fi
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
      "https://nix-community.cachix.org/"
      "https://nix-templates.cachix.org/"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nix-templates.cachix.org-1:LYR9pa1vrQsGBo+MIiGNUVDiIIKjlkUmFEVQQ939kAU="
    ];
  };
}
