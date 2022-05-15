import Layout from "components/layout";
import Link from "next/link";

const Index = () => {
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
        <a href="https://a1liu.com/tci">Teaching C Interpreter</a>, an
        interpreter of the C programming language that tries to make it easier
        to debug programs.
      </p>

      <h2>Toys</h2>
      <ul>
        <li>
          <Link href="/kilordle/">
            <a>Kilordle Clone</a>
          </Link>{" "}
          - Clone of{" "}
          <a href="https://jonesnxt.github.io/kilordle/">
            someone else&apos;s idea
          </a>
          , which was inspired by{" "}
          <a href="https://www.powerlanguage.co.uk/wordle/">Wordle</a>
        </li>
        <li>
          <Link href="/painter/">
            <a>Painter</a>
          </Link>{" "}
          - Tiny WebGL2 drawing app
        </li>
      </ul>
    </Layout>
  );
};

export default Index;
