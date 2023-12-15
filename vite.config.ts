import { sveltekit } from "@sveltejs/kit/vite";
import path from "path";

const config = {
  server: {
    fs: {
      allow: [],
    },
  },
  resolve: {
    alias: {
      "@lib": path.resolve("./src"),
    },
  },

  plugins: [sveltekit()],
};

export default config;
