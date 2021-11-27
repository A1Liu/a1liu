import Layout from "../../components/Layout";
import { dir } from "../../components/util";
// import { readdir } from "fs/promises";


// export async function getStaticProps({ params }) {
  // const allFiles = await readdir("./pages/docs");
  // const files = allFiles.filter(f => f !== "index.tsx");
  // console.log(files);

  // const props = { files: [] };
  // return { props };
// }


const Documents = ({ files }) => {
  return (
    <Layout>
      <h1>Documents</h1>
    </Layout>
  );
};

export default Documents;
