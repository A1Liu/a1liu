import { GetStaticProps, NextPage } from "next";
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
      {files.map((file) => {
        const url = `/docs/${file.replace(/\.[^/.]+$/, "")}`;

        return (
          <>
            <Link href={url}>
              <a>{url}</a>
            </Link>
            <br />
          </>
        );
      })}
    </Layout>
  );
};

export default Documents;
