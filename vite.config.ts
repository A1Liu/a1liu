import { sveltekit } from "@sveltejs/kit/vite";
import path from "path";
import type { UserConfig } from "vite";

const config = {
  server: {
    fs: {
      allow: ["./.zig/zig-out"],
    },
  },
  resolve: {
    alias: {
      "@lib": path.resolve("./src"),
      "@zig": path.resolve("./.zig/zig-out"),
    },
  },

  plugins: [sveltekit()],
};

export default config;
