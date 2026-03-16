import path from "node:path";
import { fileURLToPath } from "node:url";
import { includeIgnoreFile } from "@eslint/compat";
import { configs as eslintConfigs } from "@eslint/js";
import { defineConfig } from "eslint/config";
import eslintConfigPrettier from "eslint-config-prettier";
import { createTypeScriptImportResolver } from "eslint-import-resolver-typescript";
import { flatConfigs as importPluginConfig } from "eslint-plugin-import-x";
import { configs as nodePluginConfigs } from "eslint-plugin-n";
import { default as tseslint } from "typescript-eslint";

/** ES Modulesだと使用できない変数のエミュレート。 */
const __filename: string = fileURLToPath(import.meta.url);
/** ES Modulesだと使用できない変数のエミュレート。 */
const __dirname: string = path.dirname(__filename);
/** そのプロジェクトの.gitignoreのパス。 */
const gitignorePath: string = path.resolve(__dirname, ".gitignore");

/** ESLintが使用する設定を定義してexport。 */
const config: ReturnType<typeof defineConfig> = defineConfig(
  // どのプロジェクトでも共通して適用するルール。
  includeIgnoreFile(gitignorePath), // .gitignoreから無視するべきファイルを継承。
  eslintConfigPrettier, // prettierと競合しないようにします。
  importPluginConfig.recommended, // importの推奨プリセット。
  importPluginConfig.typescript, // importのTypeScript向け推奨プリセット。
  {
    rules: {
      // 名前別だけではなくカテゴリ別にもソートします。
      "import-x/order": ["warn", { alphabetize: { order: "asc", orderImportKind: "asc" } }],
    },
    settings: {
      // TypeScriptのimportを柔軟に解決できるようにします。
      "import-x/resolver-next": [
        createTypeScriptImportResolver({
          alwaysTryTypes: true,
        }),
      ],
    },
  },
  // ESLint全体の推奨プリセット。
  eslintConfigs.recommended,
  // typescript-eslintの推奨プリセット。
  tseslint.configs.recommendedTypeChecked,
  tseslint.configs.stylisticTypeChecked,
  {
    rules: {
      // 使ってないシンボルはアンダースコア始めにすることで警告を回避します。
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
    // TypeScript向けのルール。
    files: ["**/*.{ts,tsx,cts,mts}"],
    languageOptions: {
      parserOptions: {
        project: ["tsconfig.json"],
        tsconfigRootDir: __dirname,
      },
    },
    rules: {
      // トップレベル関数には明示的な型アノテーションを要求。
      // Haskell, Rust, Scalaコミュニティの結論と同じことを考えていて、
      // トップレベル関数は暗黙的な型推論任せにするべきではないと考えています。
      "@typescript-eslint/explicit-function-return-type": [
        "error",
        {
          allowExpressions: true, // インラインな関数式にはいちいち要求しません。
          allowConciseArrowFunctionExpressionsStartingWithVoid: true, // voidを返すことが明白な場合は要求しません。
          allowIIFEs: true, // 即時実行関数の型を持ってもあまり意味がないので要求しません。
        },
      ],
    },
  },
  {
    // TypeScriptルールでJavaScriptもlintします。
    // 主に`@ts-check`を有効にしている環境を想定しています。
    // 厳密には個別にルールを管理するべきなのですが、
    // あまり生のJavaScriptを書かないので、
    // TypeScriptルールプリセットを流用します。
    files: ["**/*.{js,jsx,cjs,mjs}"],
    languageOptions: {
      parserOptions: {
        projectService: {
          allowDefaultProject: ["*.js", "*.jsx", "*.cjs", "*.mjs"],
        },
        project: ["tsconfig.json"],
        tsconfigRootDir: __dirname,
      },
    },
  },
  // Node.js向けのルール。
  nodePluginConfigs["flat/recommended-module"],
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
);
export default config;
