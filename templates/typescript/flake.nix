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

      perSystem =
        {
          pkgs,
          lib,
          ...
        }:
        let
          inherit (pkgs) nodejs;

          npmRoot = lib.fileset.toSource {
            root = ./.;
            fileset = lib.fileset.unions [
              ./package.json
              ./package-lock.json
            ];
          };
          nodeModules = pkgs.importNpmLock.buildNodeModules {
            inherit
              nodejs
              npmRoot
              ;
          };

          tsSrc = lib.fileset.toSource {
            root = ./.;
            fileset = lib.fileset.unions [
              ./src
              ./test
              ./.editorconfig
              ./.gitignore
              ./eslint.config.ts
              ./package.json
              ./tsconfig.json
              ./vitest.config.ts
            ];
          };

          # npm run経由でスクリプト実行を簡単にするためのヘルパー。
          mkNpmCheck =
            name: script:
            pkgs.runCommand name
              {
                nativeBuildInputs = [ nodejs ];
              }
              ''
                cp -r ${tsSrc}/. .
                ln -s ${nodeModules}/node_modules node_modules
                npm run ${script}
                touch $out
              '';
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

          checks = {
            lint-eslint = mkNpmCheck "lint-eslint" "lint:eslint";
            lint-prettier = mkNpmCheck "lint-prettier" "lint:prettier";
            lint-tsc = mkNpmCheck "lint-tsc" "lint:tsc";
            test = mkNpmCheck "test" "test";
          };

          packages = {
            # flake.lockの管理バージョンをre-exportすることで安定した利用を促進。
            inherit (pkgs)
              nix-fast-build
              ;
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

              # Node.js
              nodejs
            ];
            packages = [ pkgs.importNpmLock.hooks.linkNodeModulesHook ];
            npmDeps = nodeModules;
          };
        };
    };
}
