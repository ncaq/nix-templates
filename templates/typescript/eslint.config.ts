import path from "node:path";
import { fileURLToPath } from "node:url";
import { includeIgnoreFile } from "@eslint/compat";
import eslint from "@eslint/js";
import { defineConfig } from "eslint/config";
import eslintConfigPrettier from "eslint-config-prettier";
import { createTypeScriptImportResolver } from "eslint-import-resolver-typescript";
import * as importPlugin from "eslint-plugin-import-x";
import nodePlugin from "eslint-plugin-n";
import { configs as tseslintConfigs } from "typescript-eslint";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const gitignorePath = path.resolve(__dirname, ".gitignore");

export default defineConfig(
  includeIgnoreFile(gitignorePath),
  eslintConfigPrettier,
  importPlugin.flatConfigs.recommended,
  importPlugin.flatConfigs.typescript,
  {
    rules: {
      "import-x/order": ["warn", { alphabetize: { order: "asc", orderImportKind: "asc" } }],
    },
    settings: {
      "import-x/resolver-next": [
        createTypeScriptImportResolver({
          alwaysTryTypes: true,
        }),
      ],
    },
  },
  eslint.configs.recommended,
  ...tseslintConfigs.strictTypeChecked,
  ...tseslintConfigs.stylisticTypeChecked,
  {
    languageOptions: {
      parserOptions: {
        projectService: {
          // TypeScriptルールでJavaScriptをlintする時はデフォルトのprojectを使用。
          allowDefaultProject: ["*.js", "*.jsx", "*.cjs", "*.mjs"],
        },
        tsconfigRootDir: import.meta.dirname,
      },
    },
  },
  nodePlugin.configs["flat/recommended-module"],
  {
    rules: {
      // nodeビルトインのモジュールをわかりやすくする。
      "n/prefer-node-protocol": "error",
      // 利用方法を統一したい。
      "n/prefer-global/buffer": "error",
      "n/prefer-global/console": "error",
      "n/prefer-global/process": "error",
      "n/prefer-global/text-decoder": "error",
      "n/prefer-global/text-encoder": "error",
      "n/prefer-global/url": "error",
      "n/prefer-global/url-search-params": "error",
      "n/prefer-promises/dns": "error",
      "n/prefer-promises/fs": "error",
      // 誤爆が多いし、他のlinterでカバーしているので多分必要ない。
      "n/no-missing-import": "off",
    },
  },
  // 妥当なルール改変。
  {
    rules: {
      // アンダースコアつきの引数は使わなくても無視する対象。
      "@typescript-eslint/no-unused-vars": [
        "warn",
        {
          argsIgnorePattern: "^_",
          caughtErrorsIgnorePattern: "^_",
          destructuredArrayIgnorePattern: "^_",
          varsIgnorePattern: "^_",
        },
      ],
    },
  },
  {
    files: ["**/*.{ts,cts,mts,tsx}"],
    rules: {
      "@typescript-eslint/explicit-function-return-type": ["error", { allowExpressions: true }],
    },
  },
);
