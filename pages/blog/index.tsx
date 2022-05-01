import { GetStaticProps, NextPage } from "next";
import { removeExtension, cleanJekyllSlug } from "components/util";
import Link from "next/link";
import { readdir } from "fs/promises";
import Layout from "components/layout";
import React from "react";

export interface Props {
  readonly files: string[];
}

export const getStaticProps: GetStaticProps<Props> = async ({ params }) => {
  const allFiles = await readdir("./pages/blog");
  const files = allFiles.filter((f) => f !== "index.tsx");

  const props = { files };
  return { props };
};

export const BlogContent: React.VFC<Props> = ({ files }) => {
  return (
    <>
      <p>This is my blog! Hi!</p>

      <ul style={{ display: "flex", flexDirection: "column-reverse" }}>
        {files.map((file, idx) => {
          const slug = removeExtension(file);
          const url = `/blog/${slug}`;
          const title = cleanJekyllSlug(slug);

          return (
            <li key={url}>
              <p>
                <Link href={url}>
                  <a>
                    Entry {idx + 1}: {title}
                  </a>
                </Link>
              </p>
            </li>
          );
        })}
      </ul>
    </>
  );
};

const Blog: NextPage<Props> = ({ files }) => {
  return (
    <Layout>
      <h1>Blog</h1>
      <BlogContent files={files} />
    </Layout>
  );
};

export default Blog;
