const withPWA = require("next-offline");

const withBundleAnalyzer = require("@next/bundle-analyzer")({
  enabled: process.env.ANALYZE === "true",
});

const config = {
  trailingSlash: true,
  reactStrictMode: true,
  pageExtensions: ["ts", "tsx"],
};

const pwaConfig = withPWA(config);
const analyzedConfig = withBundleAnalyzer(pwaConfig);

module.exports = analyzedConfig;
