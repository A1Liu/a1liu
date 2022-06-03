import adapter from "@sveltejs/adapter-static";
import preprocess from "svelte-preprocess";

/** @type {import('@sveltejs/kit').Config} */
const config = {
  // Consult https://github.com/sveltejs/svelte-preprocess
  // for more information about preprocessors
  preprocess: preprocess({ postcss: true }),

  kit: {
    adapter: adapter({
      pages: "out",
      assets: "out",
    }),
    trailingSlash: "always",
    prerender: {
      default: true,
    },
    files: {
      assets: "public",
    },
  },
};

export default config;
