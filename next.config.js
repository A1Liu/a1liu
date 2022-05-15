// const withPreact = require("next-plugin-preact");

const withBundleAnalyzer = require("@next/bundle-analyzer")({
  enabled: process.env.ANALYZE === "true",
});

const config = {
  trailingSlash: true,
  reactStrictMode: true,
  pageExtensions: ["ts", "tsx"],

  // webpack(config) {
  //   config.output.webassemblyModuleFilename = "static/wasm/[modulehash].wasm";

  //   // Since Webpack 5 doesn't enable WebAssembly by default, we should do it manually
  //   config.experiments = { asyncWebAssembly: true };

  //   return config;
  // },
};

// const mdxConfig = withMDX(config);
// const preactConfig = withPreact(mdxConfig);
const analyzedConfig = withBundleAnalyzer(config);

module.exports = analyzedConfig;
