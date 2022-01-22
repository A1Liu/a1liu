const withPreact = require("next-plugin-preact");

const withMDX = require("@next/mdx")({
  extension: /\.mdx$/,
  options: {
    remarkPlugins: [require("remark-prism")],
  },
});

const withBundleAnalyzer = require("@next/bundle-analyzer")({
  enabled: process.env.ANALYZE === "true",
});

const config = {
  reactStrictMode: true,
  pageExtensions: ["ts", "tsx", "mdx"],
};

const mdxConfig = withMDX(config);
const preactConfig = withPreact(mdxConfig);
const analyzedConfig = withBundleAnalyzer(preactConfig);

module.exports = analyzedConfig;
