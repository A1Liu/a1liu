import React from "react";
import type { Dispatch, SetStateAction } from "react";
import css from "./kilordle.module.css";
import * as wasm from "components/wasm";
import cx from "classnames";
import create from "zustand";
import { useAddToast } from "components/errors";

interface KilordleCb {
  submit: () => void;
  addChar: (c: string) => void;
  deleteChar: () => void;
}

interface KilordleState {
  word: string;
  callbacks: KilordleCb;
}

// https://github.com/vercel/next.js/tree/canary/examples/with-web-worker
const wasmRef: wasm.WasmRef = wasm.ref();

const KEYROWS = [
  "qwertyuiop".split(""),
  "asdfghjkl".split(""),
  ["Enter", ..."zxcvbnm".split(""), "Delete"],
];

const pressKey = (key: string, cb: KilordleCb): boolean => {
  switch (key) {
    case "Shift":
    case "Control":
    case " ":
      return false;

    case "Enter":
      cb.submit();
      break;

    case "Backspace":
    case "Delete":
      cb.deleteChar();
      break;

    default:
      if (!key.match(/^[a-zA-Z]$/)) {
        return false;
      }

      cb.addChar(key);
      break;
  }

  return true;
};

const useStore = create<KilordleState>((set, get) => {
  const deleteChar = () => set((state) => ({ word: state.word.slice(0, -1) }));
  const addChar = (c: string) =>
    set((state) => {
      if (state.word.length > 4) {
        return { word: state.word };
      }

      return { word: state.word + c.toUpperCase() };
    });

  const submit = () => {
    const word = get().word;

    if (word.length < 5) {
      return;
    }

    wasmRef.defer.submitWord(
      word.charCodeAt(0),
      word.charCodeAt(1),
      word.charCodeAt(2),
      word.charCodeAt(3),
      word.charCodeAt(4)
    );

    set({ word: "" });
  };

  return {
    word: "",
    callbacks: { submit, addChar, deleteChar },
  };
});

const Puzzle: React.VFC<{ index: number }> = ({ index }) => {
  return null;
};

export const Kilordle: React.VFC = () => {
  const word = useStore((state) => state.word);
  const cb = useStore((state) => state.callbacks);

  const keyboardRef = React.useRef<HTMLInputElement>(null);
  const addToast = useAddToast();

  React.useEffect(() => {
    const listener = (evt: KeyboardEvent) => {
      if (evt.ctrlKey || evt.metaKey || evt.altKey) {
        return;
      }

      if (pressKey(evt.key, cb)) {
        evt.preventDefault();
      }
    };

    window.addEventListener("keydown", listener);

    return () => {
      console.log("deleting");
      window.removeEventListener("keydown", listener);
    };
  }, [cb]);

  React.useEffect(() => {
    const postMessage = (tag: string, data: any) => {
      console.log(tag, data);

      if (typeof data === "string") {
        addToast(data);
      }
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
                    onClick={() => pressKey(key, cb)}
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
