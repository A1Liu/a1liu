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
    <img src={"/pfp.jpg"} alt="me" />

    <h2>About Me</h2>
    <p>
      Hi, I&apos;m Albert, and this is my website! I&#39;m a Software Engineer
      at Bedrock Security, where I am the primary owner of our user-facing application and API surface.
      Before that, I was a full-stack engineer at Dandy, building internal operations tooling.
    </p>

    <h2>What I&apos;m Doing Now</h2>
    <p>
      I'm working at Bedrock Security, which recently exited stealth mode,
      and also trying to learn to freeskate. I'm also working on 
      <a href="https://github.com/A1Liu/webb">a framework for local-first application development</a>.
    </p>

    <h2>Projects</h2>
    <ul>
    <!-- These projects have been broken as of the latest Zig update;
          I feel too tired to put in the effort to maintain them, but I
          still want to update the website, so removing them will have to
          do for now.
      <li>
        <a href="/game-2d-simple/">Simple 2D Game</a>{" "}
        - Really simple 2D game
      </li>

      <li>
        <a href="/painter/">Painter</a>{" "}
        - Tiny WebGL2 drawing app
      </li>

      <li>
        <a href="/kilordle/">Kilordle Clone</a>{" "}
        - Clone of{" "}
        <a href="https://jonesnxt.github.io/kilordle/">
          someone else&apos;s idea</a
        >, which was inspired by{" "}
        <a href="https://www.nytimes.com/games/wordle/index.html">Wordle</a>
      </li>

      -->

      <li>
        <a href="https://github.com/A1Liu/webb">Distributed Application Framework</a>{" "}
        - A framework for building privacy-protecting local-first applications in iOS and Web
      </li>

      <li>
        <a href="https://tci.a1liu.com/">Teaching C Interpreter</a>{" "}
        - interpreter for the C programming language that tries to make it easier
        to debug programs.
      </li>

      <li>
        <a href="https://nyu.a1liu.com/api/">Schedge</a>{" "}
        - API for NYU&apos;s course catalog
      </li>
    </ul>
  </div>
</div>

<style lang="postcss">
  .fullscreen {
    background-color: #e6e6e6;
    position: fixed;
    top: 0;
    left: 0;
    height: 100%;
    width: 100%;
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

    @media (--min-lg) {
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

    @media (--min-lg) {
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
