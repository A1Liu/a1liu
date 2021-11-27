import Layout from "../../components/Layout";
import { dir } from "../../components/util";
import { readdir } from "fs/promises";

export async function getStaticProps({ params }) {
  const allFiles = await readdir("./pages/docs");
  const files = allFiles.filter((f) => f !== "index.tsx");

  const props = { files };
  return { props };
}

const Documents = ({ files }) => {
  const urls = files.map((f) => `/docs/${f.replace(/\.[^/.]+$/, "")}`);

  return (
    <Layout>
      <h1>Documents</h1>
      {urls.map((url) => {
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
