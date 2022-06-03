<div class="fullscreen">
  <div class="topNav">
    <div class="navContent">
      <a href="/" class="navLink logo">Albert Liu</a>

      <nav>
        <a href="/" class="navLink navItem">Home</a>
      </nav>
    </div>
  </div>

  <div class="main">
    <img src={"/apps/pfp.jpg"} alt="me" />

    <h2>About Me</h2>
    <p>
      Hi, I&apos;m Albert, and this is my website! I&apos;m a Senior at NYU
      majoring in Computer Science. This website is mainly for my own personal
      use, but feel free to use the stuff on here or copy the source code into
      your own project! (Please read and follow the license though.)
    </p>

    <h2>What I&apos;m Doing Now</h2>
    <p>
      Slowly learning things here and there while working on
      <a href="/painter/">Painter</a>{" "}and other projects.
    </p>

    <h2>Projects</h2>
    <ul>
      <li>
        <a href="https://schedge.a1liu.com/">Schedge</a>{" "}
        - API for NYU&apos;s course catalog
      </li>

      <li>
        <a href="https://tci.a1liu.com/">Teaching C Interpreter</a>{" "}
        - interpreter for the C programming language that tries to make it easier
        to debug programs.
      </li>

      <li>
        <a href="/apps/kilordle/">Kilordle Clone</a>{" "}
        - Clone of{" "}
        <a href="https://jonesnxt.github.io/kilordle/">
          someone else&apos;s idea
        </a>
        , which was inspired by{" "}
        <a href="https://www.powerlanguage.co.uk/wordle/">Wordle</a>
      </li>

      <li>
        <a href="/apps/painter/">Painter</a>{" "}
        - Tiny WebGL2 drawing app
      </li>
    </ul>
  </div>
</div>

<style lang="postcss">
  $min-lg: (min-width: 992px);

  .fullscreen {
    background-color: #e6e6e6;
    position: fixed;
    top: 0;
    left: 0;
    height: 100vh;
    width: 100vw;
    display: flex;
    flex-direction: column;
    justify-items: space-between;
    align-items: center;
    overflow-y: scroll;
  }

  .topNav {
    width: 100%;
    min-height: 90px;
    height: 90px;
    background: #121417;
    display: flex;
    flex-direction: row;
    justify-content: center;
  }

  .navContent {
    height: 100%;
    display: flex;
    justify-content: space-between;
    flex-direction: row;
    align-items: center;
    padding: 0 16px;
    width: 100%;

    @media $min-lg {
      padding: 0;
      flex-basis: 66.666667%;
      width: 66.666667%;
    }
  }

  .navLink {
    color: var(--gray);

    &:hover {
      color: var(--blue);
    }
  }

  .logo {
    min-width: 0;
    font-size: 30px;
  }

  .navItem {
    margin-left: 10px;
    font-size: 20px;
  }

  img {
    width: 200px;
    height: 200px;
    margin-left: 15px;
    float: right;
  }

  .main {
    flex-grow: 1;
    background-color: #fff;
    width: 100%;
    padding: 50px;

    @media $min-lg {
      width: 66.666667%;
      box-shadow: inset -15px 0 15px -15px #282c34,
        inset 15px 0 15px -15px #282c34;
    }

    & p {
      margin-bottom: 0.8rem;
    }

    & a {
      -webkit-text-decoration-skip: objects;

      color: var(--blue);
      transition: 0.4s;

      &:hover {
        color: var(--gray);
      }
    }

    & ul {
      padding-left: 40px;
    }

    & h2 {
      font-size: 1.6rem;
      font-weight: 500;
      line-height: 1.2;
      margin-bottom: 0.4rem;
    }

    /*
    & h1 {
      font-size: 2rem;
      font-weight: 500;
      line-height: 1.2;
      margin-bottom: 0.4rem;
    }

    & h3 {
      font-weight: 500;
      line-height: 1.2;
      margin-bottom: 0.4rem;
    }

    & h4 {
      font-size: 1.2rem;
      font-weight: 500;
      line-height: 1.2;
      margin-bottom: 0.4rem;
    }

    & h5 {
      font-weight: 500;
      line-height: 1.2;
      margin-bottom: 0.4rem;
    }

    & h6 {
      font-weight: 500;
      line-height: 1.2;
      margin-bottom: 0.4rem;
    }

    & :not(pre) > code:not(.no-style) {
    padding: 3px 5px 3px 5px;
    border-radius: 5px;
    white-space: nowrap;
    background: #282c34;
    }

    & div:global(.remark-highlight) > pre,
    & :not(pre) > code:not(.no-style) {
    color: #98c379;
    }

    & code {
    font-family: monospace;
    font-size: 0.875rem;
    word-spacing: normal;
    word-break: normal;
    tab-size: 4;
    hyphens: none;
    }

    & pre {
    margin-bottom: 1rem;
    overflow: auto;
    word-spacing: normal;
    word-break: normal;
    tab-size: 4;
    hyphens: none;
    }

    & div:global(.remark-highlight) > pre {
    padding: 15px;
    border-radius: 10px;

    box-shadow: inset -15px 15px 15px -15px #282c34,
    inset 15px -15px 15px -15px #282c34;
    }
     */
  }
</style>
