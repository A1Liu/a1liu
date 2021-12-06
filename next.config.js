const withPreact = require("next-plugin-preact");

const withMDX = require("@next/mdx")({
  extension: /\.mdx$/,
  options: {
    remarkPlugins: [require("remark-prism")],
  },
});

const config = {
  reactStrictMode: true,
  pageExtensions: ["tsx", "mdx"],
};

const mdxConfig = withMDX(config);
const preactConfig = withPreact(mdxConfig);

module.exports = preactConfig;
