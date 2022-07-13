<script lang="ts">
  import { onMount } from "svelte";
  import * as wasm from "@lib/ts/wasm";
  import Toast, { postToast } from "@lib/svelte/errors.svelte";
  import wasmUrl from "@zig/kilordle.wasm?url";
  import { defer } from "@lib/ts/util";

  interface PuzzleData {
    solution: string;
    filled: string;
    submits: string;
  }

  const KEYROWS = [
    "qwertyuiop".split(""),
    "asdfghjkl".split(""),
    ["Go", ..."zxcvbnm".split(""), "Del"],
  ];

  let wasmRef: wasm.Ref | undefined = undefined;

  let word: string = "";
  let puzzles: PuzzleData[] = [];
  let submissionCount: number = 0;
  let wordsLeft: number = 0;
  let foundLetters: Record<string, true> = {};

  let submitError: boolean = false;
  let timeout: any = undefined;

  let keyboard: any = undefined;

  const reset = () => {
    if (!wasmRef) return;

    wasmRef.abi.reset();

    word = "";
    submissionCount = 0;
    submitError = false;
    puzzles = [];
    foundLetters = {};
  };

  const addChar = (c: string) => {
    if (word.length > 4) {
      return;
    }

    word = word + c.toLowerCase();
    submitError = false;
  };

  const pressKey = (key: string): boolean => {
    switch (key) {
      case "Shift":
      case "Control":
      case " ":
        return false;

      case "Enter":
      case "Go": {
        if (word.length < 5) break;
        if (!wasmRef) break;

        const chars = word.split("");
        const codes = chars.map((c) => c.charCodeAt(0));

        defer(() => {
          if (!wasmRef.abi.submitWord(...codes)) {
            submitError = true;
            return;
          }

          const notFound = chars.filter((l) => !foundLetters[l]);
          notFound.forEach((letter) => {
            foundLetters[letter] = true;
          });
        });
        break;
      }

      case "Backspace":
      case "Delete":
      case "Del":
        word = word.slice(0, -1);
        break;

      default:
        if (!key.match(/^[a-zA-Z]$/)) {
          return false;
        }

        addChar(key);
        break;
    }

    return true;
  };

  $: {
    if (submitError) {
      timeout = setTimeout(() => (submitError = false), 1000);
    } else {
      clearTimeout(timeout);
      timeout = undefined;
    }
  }

  onMount(() => {
    // NOTE: we use RTF file extension here, even though this file is technically
    // binary, because RTF is gzip'd by Github Pages. For non-gzip files, use `.bin`
    const data = wasm.fetchAsset("/kilordle/data.rtf");
    const wasmPromise = wasm.fetchWasm(wasmUrl, {
      postMessage: postToast,

      raw: (wasmRef: wasm.Ref) => ({
        resetSubmission: () => {
          word = "";
          submitError = false;
        },

        incrementSubmissionCount: () => (submissionCount += 1),
        setWordsLeft: (words: number) => (wordsLeft = words),
        setPuzzles: (puzzleDataId: number) => {
          puzzles = wasmRef.readObj(puzzleDataId);
        },

        addChar: (code: number) => {
          const character = String.fromCharCode(code);
          addChar(character);
        },
      }),
    });

    Promise.all([wasmPromise, data]).then(([ref, data]) => {
      const dataId = ref.addObj(data);

      ref.abi.init(dataId);
      wasmRef = ref;
    });

    keyboard?.focus();

    const listener = (evt: KeyboardEvent) => {
      if (evt.ctrlKey || evt.metaKey || evt.altKey) {
        return;
      }

      if (pressKey(evt.key)) {
        evt.preventDefault();
      }
    };

    window.addEventListener("keydown", listener);

    return () => {
      console.log("unmounting");
      window.removeEventListener("keydown", listener);
    };
  });
</script>

<svelte:head>
  <title>Kilordle</title>
  <link rel="manifest" href="/kilordle/kilordle.webmanifest" />
  <link rel="shortcut icon" href="/kilordle/k-emoji.svg" />
  <meta name="theme-color" content="#1976D2" />
</svelte:head>

<Toast />

<div class="wrapper">
  <div class="topBar">
    <div class="submitWindow" class:shake={submitError}>
      <div class="letterBox">{word[0] ?? ""}</div>
      <div class="letterBox">{word[1] ?? ""}</div>
      <div class="letterBox">{word[2] ?? ""}</div>
      <div class="letterBox">{word[3] ?? ""}</div>
      <div class="letterBox">{word[4] ?? ""}</div>
    </div>

    <div class="statsBox">
      <div>Guesses: {submissionCount}</div>
      <div>Words: {wordsLeft}</div>
    </div>
  </div>

  <div class="centerArea">
    <!-- <PuzzleArea /> -->
    {#if submissionCount === 0}
      <div class="centerMessage">
        {"No submissions yet. Try typing a word and hitting 'Enter'!"}
      </div>
    {:else if wordsLeft === 0}
      <div class="centerMessage">
        <p>{"You won!"}</p>
        <button class="muiButton" on:click={reset}>Play again</button>
      </div>
    {:else}
      <div class="guessesArea">
        {#each puzzles as puzzle (puzzle.solution)}
          <div class="puzzle">
            <div class="filledBox">
              {#each puzzle.filled.split("") as letter, idx}
                <!--
                  We use the isLower test here instead of checking against
                  space so that in debug builds we can see the actual solution
                  and double-check that everything is kosher. This logic ensures
                  that lowercase letters and space are output as white and
                  uppercase are green.
                -->

                <div
                  class="letterBox"
                  class:green={letter.toLowerCase() !== letter}
                >
                  {letter}
                </div>
              {/each}
            </div>

            {#each puzzle.submits.split(",") as submit}
              <div class="submitBox">
                {#each submit.split("") as letter}
                  <div
                    class="letterBox"
                    class:yellow={letter.toUpperCase() === letter}
                  >
                    {letter}
                  </div>
                {/each}
              </div>
            {/each}
          </div>
        {/each}
      </div>
    {/if}
  </div>

  <div bind:this={keyboard} class="keyboard">
    {#each KEYROWS as row, idx}
      <div class="keyboardRow" class:middleRow={idx === 1}>
        {#each row as key}
          <button
            class="keyBox"
            class:gray={foundLetters[key]}
            on:click={() => pressKey(key)}
          >
            {key}
          </button>
        {/each}
      </div>
    {/each}
  </div>
</div>

<style lang="postcss">
  @import "@lib/svelte/util.module.css";

  .wrapper {
    height: 100vh;
    width: 100vw;

    display: flex;
    flex-direction: column;
    flex-wrap: nowrap;

    touch-action: manipulation;
  }

  .topBar {
    display: flex;
    flex-direction: row;
    justify-content: space-between;
    align-items: center;
    border-bottom: 4px solid gray;

    @media (--max-sm) {
      padding: 4px 8px 4px 4px;
    }

    @media (--min-sm) {
      position: relative;
      padding: 4px 16px 4px 16px;
    }
  }

  .submitWindow {
    font-size: 2rem;
    font-family: "Dank Mono", "Fira Code", monospace;

    display: flex;
    flex-direction: row;
    align-items: center;
    gap: 4px;

    @media (--max-sm) {
    }

    @media (--min-sm) {
      position: absolute;
      left: 50%;
      transform: translate(-50%, 0%);
    }
  }

  .statsBox {
    display: flex;
    flex-direction: column;
    align-items: flex-end;
    justify-content: center;

    margin-left: auto;
  }

  .letterBox {
    border-radius: 8px;
    border: 1px solid gray;
    width: 1em;
    height: 1.5em;

    display: flex;
    flex-direction: row;
    align-items: center;
    justify-content: center;

    text-transform: uppercase;
  }

  .centerArea {
    overflow-y: scroll;
    flex: 1;
    max-height: inherit;

    display: flex;
    flex-direction: row;
    flex-wrap: nowrap;
    justify-content: center;
  }

  .guessesArea {
    display: flex;
    flex-direction: row;
    flex-wrap: wrap;

    @media (--min-lg) {
      max-width: lg;
    }

    padding: 8px;
    gap: 1rem;
  }

  .centerMessage {
    flex: 1;

    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    text-align: center;
  }

  .puzzle {
    display: flex;
    flex-direction: column;
    gap: 4px;
  }

  .filledBox {
    display: flex;
    flex-direction: row;
    gap: 4px;
  }

  .submitBox {
    display: flex;
    flex-direction: row;
    gap: 4px;
  }

  .keyboard {
    display: flex;
    flex-direction: column;
    flex-wrap: nowrap;
    align-items: center;
    gap: 8px;

    font-weight: bold;
    padding: 1em 4px 1em 4px;

    font-size: 24px;
  }

  .keyboardRow {
    display: flex;
    flex-direction: row;
    flex-wrap: nowrap;
    gap: 4px;
    justify-content: space-between;

    width: 100%;
    max-width: 500px;
  }

  .middleRow {
    @media (--max-sm) {
      padding: 0px 8px 0px 8px;
    }

    @media (--min-sm) {
      padding: 0px 16px 0px 16px;
    }
  }

  .keyBox {
    border-radius: 8px;
    border: 1px solid gray;

    height: 58px;
    padding: 4px;
    text-decoration: none;
    color: black;

    display: flex;
    flex-direction: row;
    align-items: center;
    justify-content: center;
    flex-grow: 1;
    flex-basis: 0;
    text-transform: uppercase;
  }

  .yellow {
    background-color: yellow;
  }

  .green {
    background-color: lightgreen;
  }

  .gray {
    background-color: gray;
  }

  /* https://css-tricks.com/snippets/css/shake-css-keyframe-animation/ */
  .shake {
    backface-visibility: hidden;
    perspective: 1000px;

    @media (--max-sm) {
      animation: shake 0.82s cubic-bezier(0.36, 0.07, 0.19, 0.97) both;
    }

    @media (--min-sm) {
      animation: shake-translated 0.82s cubic-bezier(0.36, 0.07, 0.19, 0.97)
        both;
    }
  }

  @keyframes shake-translated {
    0%,
    100% {
      transform: translate(-50%, 0%);
    }

    10%,
    90% {
      transform: translate(-50%, 0%) translate3d(-1px, 0, 0);
    }

    20%,
    80% {
      transform: translate(-50%, 0%) translate3d(2px, 0, 0);
    }

    30%,
    50%,
    70% {
      transform: translate(-50%, 0%) translate3d(-4px, 0, 0);
    }

    40%,
    60% {
      transform: translate(-50%, 0%) translate3d(4px, 0, 0);
    }
  }

  @keyframes shake {
    10%,
    90% {
      transform: translate3d(-1px, 0, 0);
    }

    20%,
    80% {
      transform: translate3d(2px, 0, 0);
    }

    30%,
    50%,
    70% {
      transform: translate3d(-4px, 0, 0);
    }

    40%,
    60% {
      transform: translate3d(4px, 0, 0);
    }
  }
</style>
