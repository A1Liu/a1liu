import React from "react";
import type { Dispatch, SetStateAction } from "react";
import css from "./kilordle.module.css";
import * as wasm from "components/wasm";
import cx from "classnames";
import { useAddToast } from "components/errors";

// https://github.com/vercel/next.js/tree/canary/examples/with-web-worker

const wasmRef: wasm.WasmRef = wasm.ref();

const KEYROWS = [
  "qwertyuiop".split(""),
  "asdfghjkl".split(""),
  ["Enter", ..."zxcvbnm".split(""), "Delete"],
];

const pressKey = (
  key: string,
  setWord: Dispatch<SetStateAction<string>>
): boolean => {
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

        console.log("DEBUG: submit");
        // dispatch to zig here; Since the zig code might do setState operations,
        // We dispatch it to happen on the next iteration, instead of doing it
        // right now
        wasmRef.abi.submitWord(
          word.charCodeAt(0),
          word.charCodeAt(1),
          word.charCodeAt(2),
          word.charCodeAt(3),
          word.charCodeAt(4)
        );

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

  return true;
};

const Puzzle: React.VFC<{ index: number }> = ({ index }) => {
  return null;
};

export const Kilordle: React.VFC = () => {
  const [word, setWord] = React.useState("");
  const [guesses, setGuesses] = React.useState<string[]>([]);
  const [puzzles, setPuzzles] = React.useState<string[]>([]);
  const keyboardRef = React.useRef<HTMLInputElement>(null);
  const addToast = useAddToast();

  React.useEffect(() => {
    const listener = (evt: KeyboardEvent) => {
      if (evt.ctrlKey || evt.metaKey || evt.altKey) {
        return;
      }

      if (pressKey(evt.key, setWord)) {
        evt.preventDefault();
      }
    };

    window.addEventListener("keydown", listener);

    return () => {
      console.log("deleting");
      window.removeEventListener("keydown", listener);
    };
  }, [setWord]);

  React.useEffect(() => {
    const postMessage = (tag: string, data: any) => {
      console.log(tag, data);

      // if (typeof data === "string") {
      //   addToast(data);
      // }
    };

    wasm
      .fetchWasm("/assets/kilordle.wasm", wasmRef, { postMessage })
      .then((ref) => {
        ref.abi.init();
      });
  }, [addToast]);

  React.useEffect(() => {
    keyboardRef.current?.focus();
  }, [keyboardRef]);

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
      <div ref={keyboardRef} className={css.keyboard}>
        {KEYROWS.map((row, idx) => {
          return (
            <div key={idx} className={css.keyboardRow}>
              {row.map((key) => {
                return (
                  <button
                    key={key}
                    className={css.keyBox}
                    onClick={() => pressKey(key, setWord)}
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
