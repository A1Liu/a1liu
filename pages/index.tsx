import Layout from "components/layout";
import Link from "next/link";
import { BlogContent, getStaticProps as blogProps, Props } from "./blog";

export const getStaticProps: GetStaticProps<Props> = async (props) => {
  return blogProps(props);
};

const Index: NextPage<Props> = ({ files }) => {
  return (
    <Layout>
      <img
        style={{ width: "200px", marginLeft: "15px", float: "right" }}
        src="/assets/pfp.jpg"
      />

      <h2>About Me</h2>
      <p>
        {`Hi, I'm Albert, and this is my website! I'm a Senior at NYU majoring `}
        {`in Computer Science. This website is mainly for my own personal use, `}
        {`but feel free to use the stuff on here or copy the source code into `}
        {`your own project!  (Please read and follow the license though.)`}
      </p>

      <h2>What I'm Doing Now</h2>
      <p>
        {`Right now I'm working on `}
        <Link href="https://a1liu.com/tci">
          <a>Teaching C Interpreter</a>
        </Link>
        , an interpreter of the C programming language that tries to make it
        easier to debug programs.
      </p>

      <h2>Blog</h2>
      <BlogContent files={files} />
    </Layout>
  );
};

export default Index;
