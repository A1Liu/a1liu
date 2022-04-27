import React from "react";
import css from "./kilordle.module.css";
import * as wasm from "components/wasm";

// https://github.com/vercel/next.js/tree/canary/examples/with-web-worker

const wasmRef: wasm.WasmRef = {
  instance: null,
  abiExports: null,
  postMessage: console.log,
};

export const Kilordle: React.VFC = () => {
  React.useEffect(() => {
    wasm.fetchWasm("/kilordle.wasm", wasmRef).then((ref) => {
      const result = ref.abiExports.add(1, 2);
      console.log(result);
    });
  }, []);

  const [word, setWord] = React.useState("");

  React.useEffect(() => {
    window.addEventListener("keydown", (evt) => {
      if (evt.ctrlKey || evt.metaKey || evt.altKey) {
        return;
      }

      switch (evt.key) {
        case "Shift":
        case "Control":
        case " ":
          break;

        case "Backspace":
        case "Delete":
          evt.preventDefault();

          setWord((word) => word.slice(0, -1));
          break;

        default:
          if (!evt.key.match(/^[a-zA-Z]$/)) {
            return;
          }

          evt.preventDefault();
          const key = evt.key.toUpperCase();

          setWord((word) => {
            if (word.length > 4) {
              return word;
            }

            return word + key;
          });
          break;
      }

      console.log(evt);
      console.log(evt.keyCode);
    });
  }, [setWord]);

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
      <div className={css.keyboard}></div>
    </div>
  );
};

export default Kilordle;
