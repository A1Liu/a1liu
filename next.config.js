const withPWA = require("next-pwa");

const withBundleAnalyzer = require("@next/bundle-analyzer")({
  enabled: process.env.ANALYZE === "true",
});

const config = {
  trailingSlash: true,
  reactStrictMode: true,
  pageExtensions: ["ts", "tsx"],

  pwa: {
    dest: "public",
  },
};

const pwaConfig = withPWA(config);
const analyzedConfig = withBundleAnalyzer(pwaConfig);

module.exports = analyzedConfig;
