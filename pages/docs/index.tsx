import { GetStaticProps, NextPage } from "next";
import { removeExtension, cleanJekyllSlug } from "components/util";
import Link from "next/link";
import Layout from "components/layout";
import { readdir } from "fs/promises";

export interface Props {
  readonly files: string[];
}

export const getStaticProps: GetStaticProps<Props> = async ({ params }) => {
  const allFiles = await readdir("./pages/docs");
  const files = allFiles.filter((f) => f !== "index.tsx");

  const props = { files };
  return { props };
};

const Documents: NextPage<Props> = ({ files }) => {
  return (
    <Layout>
      <h1>Documents</h1>

      <ul>
        {files.map((file) => {
          const slug = removeExtension(file);
          const url = `/docs/${slug}`;
          const title = cleanJekyllSlug(slug);

          return (
            <li key={url}>
              <Link href={url}>
                <a>{title}</a>
              </Link>
              <br />
            </li>
          );
        })}
      </ul>
    </Layout>
  );
};

export default Documents;
