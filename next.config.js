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

module.exports = withMDX(config);
