import { configDefaults, defineConfig } from "vitest/config";

const config: ReturnType<typeof defineConfig> = defineConfig({
  build: {
    outDir: "dist",
  },
  test: {
    include: ["test/**/*.test.ts"],
    exclude: [...configDefaults.exclude, "**/.direnv/**", "**/dist/**"],
  },
});
export default config;
