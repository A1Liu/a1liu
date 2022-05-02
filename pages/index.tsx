import Layout from "components/layout";
import { GetStaticProps, NextPage } from "next";
import Link from "next/link";
import { BlogContent, getStaticProps as blogProps, Props } from "./blog";

export const getStaticProps: GetStaticProps<Props> = async (props) => {
  return blogProps(props);
};

const Index: NextPage<Props> = ({ files }) => {
  return (
    <Layout>
      <img
        src={"/assets/pfp.jpg"}
        alt="a picture of me"
        style={{
          width: "200px",
          height: "200px",
          marginLeft: "15px",
          float: "right",
        }}
      />

      <h2>About Me</h2>
      <p>
        Hi, I&apos;m Albert, and this is my website! I&apos;m a Senior at NYU
        majoring in Computer Science. This website is mainly for my own personal
        use, but feel free to use the stuff on here or copy the source code into
        your own project! (Please read and follow the license though.)
      </p>

      <h2>What I&apos;m Doing Now</h2>
      <p>
        Right now I&apos;m working on{" "}
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
