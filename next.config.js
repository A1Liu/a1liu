const withMDX = require('@next/mdx')({
  extension: /\.mdx$/,
});

const config = {
  reactStrictMode: true,
  pageExtensions: ['tsx', 'mdx'],
}

module.exports = withMDX(config);
