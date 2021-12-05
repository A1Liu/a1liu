import { GetStaticProps, NextPage } from "next";
import Layout from "components/Layout";
import { readdir } from "fs/promises";

interface Props {
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
            <a href={url}>{url}</a>
            <br />
          </>
        );
      })}
    </Layout>
  );
};

export default Documents;