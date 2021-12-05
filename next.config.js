const withMDX = require("@next/mdx")({
  extension: /\.mdx$/,
  options: {
    remarkPlugins: [require("remark-prism")],
  },
});

const config = {
  reactStrictMode: true,
  pageExtensions: ["tsx", "mdx"],
  webpack: (config, { buildId, dev, isServer, defaultLoaders, webpack }) => {
    config.module.rules.push({
      test: /\.ts(x?)$/,
      use: [defaultLoaders.babel, "ts-loader"],
    });

    return config;
  },
};

module.exports = withMDX(config);
