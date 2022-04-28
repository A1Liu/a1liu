import React from "react";
import css from "./kilordle.module.css";
import * as wasm from "components/wasm";
import cx from "classnames";

// https://github.com/vercel/next.js/tree/canary/examples/with-web-worker

const wasmRef: wasm.WasmRef = {
  instance: null,
  abiExports: null,
  postMessage: console.log,
};

const KEYROWS = [
  "qwertyuiop".split(""),
  "asdfghjkl".split(""),
  ["Enter", ..."zxcvbnm".split(""), "Delete"],
];

const Puzzle: React.VFC<{ index: number }> = ({ index }) => {
  return null;
};

export const Kilordle: React.VFC = () => {
  const [word, setWord] = React.useState("");
  const [guesses, setGuesses] = React.useState<string[]>([]);
  const [puzzles, setPuzzles] = React.useState<string[]>([]);

  const pressKey = React.useCallback(
    (key: string): boolean => {
      switch (key) {
        case "Shift":
        case "Control":
        case " ":
          return false;

        case "Enter":
          setWord((word) => {
            if (word.length < 5) {
              return word;
            }

            // dispatch to zig here

            return "";
          });
          break;

        case "Backspace":
        case "Delete":
          setWord((word) => word.slice(0, -1));
          break;

        default:
          if (!key.match(/^[a-zA-Z]$/)) {
            return false;
          }

          setWord((word) => {
            if (word.length > 4) {
              return word;
            }

            return word + key.toUpperCase();
          });
          break;
      }

      console.log(key);

      return true;
    },
    [setWord]
  );

  React.useEffect(() => {
    const listener = (evt: KeyboardEvent) => {
      if (evt.ctrlKey || evt.metaKey || evt.altKey) {
        return;
      }

      if (pressKey(evt.key)) {
        evt.preventDefault();
      }

      console.log(evt);
    };

    window.addEventListener("keydown", listener);

    return () => {
      console.log("deleting");
      window.removeEventListener("keydown", listener);
    };
  }, [pressKey]);

  React.useEffect(() => {
    wasm.fetchWasm("/assets/kilordle.wasm", wasmRef).then((ref) => {
      const result = ref.abiExports.add(1, 2);
      console.log(result);
    });
  }, []);

  return (
    <div className={css.wrapper}>
      {/* current word */}
      <div className={css.topBar}>
        <div className={css.letterBox}>{word[0]}</div>
        <div className={css.letterBox}>{word[1]}</div>
        <div className={css.letterBox}>{word[2]}</div>
        <div className={css.letterBox}>{word[3]}</div>
        <div className={css.letterBox}>{word[4]}</div>
      </div>

      {/* viewable area */}
      <div className={css.guessesArea}></div>

      {/* keyboard */}
      <div className={css.keyboard}>
        {KEYROWS.map((row, idx) => {
          return (
            <div key={idx} className={css.keyboardRow}>
              {row.map((key) => {
                return (
                  <button
                    key={key}
                    className={css.keyBox}
                    onClick={() => pressKey(key)}
                  >
                    {key}
                  </button>
                );
              })}
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default Kilordle;
