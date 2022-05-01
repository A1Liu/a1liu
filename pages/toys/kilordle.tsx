import React from "react";
import type { Dispatch, SetStateAction } from "react";
import css from "./kilordle.module.css";
import * as wasm from "components/wasm";
import cx from "classnames";
import create from "zustand";
import { useToast, ToastColors } from "components/errors";

interface PuzzleData {
  solution: string;
  filled: string;
  submits: string[];
}

interface PuzzleWasmData {
  solution: string;
  filled: string;
  submits: string;
}

interface KilordleCb {
  submit: () => void;
  addChar: (c: string) => void;
  deleteChar: () => void;
  setPuzzles: (puzzles: PuzzleWasmData[]) => void;
}

interface KilordleState {
  foundLetters: Record<string, true>;
  word: string;
  puzzles: PuzzleData[];
  callbacks: KilordleCb;
}

// https://github.com/vercel/next.js/tree/canary/examples/with-web-worker
const wasmRef: wasm.WasmRef = wasm.ref();

const KEYROWS = [
  "qwertyuiop".split(""),
  "asdfghjkl".split(""),
  ["Enter", ..."zxcvbnm".split(""), "Del"],
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
    case "Del":
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
    const state = get();
    const { word, foundLetters } = get();

    if (word.length < 5) {
      return;
    }

    wasmRef.defer
      .submitWord(
        word.charCodeAt(0),
        word.charCodeAt(1),
        word.charCodeAt(2),
        word.charCodeAt(3),
        word.charCodeAt(4)
      )
      .then((success) => {
        if (!success) {
          return;
        }

        const newFounds: Record<string, true> = {};
        const foundCount = 0;

        word.toLowerCase().split("").forEach((letter) => {
          if (!foundLetters[letter]) {
            newFounds[letter] = true;
            foundCount += 1;
          }
        });

        if (foundCount > 0) {
          set({ foundLetters: { ...foundLetters, ...newFounds } });
        }
      });

    set({ word: "" });
  };

  const setPuzzles = (puzzles: PuzzleWasmData[]) => {
    console.log(puzzles);
    set({
      puzzles: puzzles.map((puzzle) => {
        return {
          ...puzzle,
          submits: puzzle.submits.split(","),
        };
      }),
    });
  };

  return {
    word: "",
    foundLetters: {},
    puzzles: [],
    callbacks: { submit, addChar, deleteChar, setPuzzles },
  };
});

const TopBar: React.VFC = () => {
  const word = useStore((state) => state.word);

  return (
    <div className={css.topBar}>
      <div className={css.letterBox}>{word[0]}</div>
      <div className={css.letterBox}>{word[1]}</div>
      <div className={css.letterBox}>{word[2]}</div>
      <div className={css.letterBox}>{word[3]}</div>
      <div className={css.letterBox}>{word[4]}</div>
    </div>
  );
};

const Keyboard: React.VFC = () => {
  const keyboardRef = React.useRef<HTMLInputElement>(null);
  const foundLetters = useStore((state) => state.foundLetters);
  const cb = useStore((state) => state.callbacks);

  React.useEffect(() => {
    keyboardRef.current?.focus();
  }, [keyboardRef]);

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

  return (
    <div ref={keyboardRef} className={css.keyboard}>
      {KEYROWS.map((row, idx) => {
        return (
          <div key={idx} className={css.keyboardRow}>
            {row.map((key) => {
              return (
                <button
                  key={key}
                  className={cx(css.keyBox, foundLetters[key] && css.gray)}
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
  );
};

const Puzzle: React.VFC<{ puzzle: PuzzleData }> = ({ puzzle }) => {
  return (
    <div className={css.puzzle}>
      <div className={css.filledBox}>
        {puzzle.filled.split("").map((letter, idx) => {
          const upper = letter.toUpperCase();
          const isUpper = letter === upper;

          return (
            <div
              key={idx}
              className={cx(css.letterBox, letter !== " " && css.green)}
            >
              {upper}
            </div>
          );
        })}
      </div>

      {puzzle.submits.map((submit) => (
        <div key={submit} className={css.submitBox}>
          {submit.split("").map((letter, idx) => {
            const upper = letter.toUpperCase();
            const isUpper = letter === upper;

            return (
              <div
                key={idx}
                className={cx(css.letterBox, isUpper && css.yellow)}
              >
                {upper}
              </div>
            );
          })}
        </div>
      ))}
    </div>
  );
};

const PuzzleArea: React.VFC = () => {
  const puzzles = useStore((state) => state.puzzles);

  return (
    <div className={css.guessesArea}>
      {puzzles.map((puzzle) => (
        <Puzzle key={puzzle.solution} puzzle={puzzle} />
      ))}
    </div>
  );
};

export const Kilordle: React.VFC = () => {
  const cb = useStore((state) => state.callbacks);
  const toast = useToast();

  React.useEffect(() => {
    const postMessage = (tag: string, data: any) => {
      console.log(tag, data);

      if (typeof data === "string") {
        toast.add(ToastColors[tag] ?? "green", null, data);
      }
    };

    wasm
      .fetchWasm("/assets/kilordle.wasm", wasmRef, {
        postMessage,
        setPuzzles: cb.setPuzzles,
      })
      .then((ref) => {
        ref.abi.init();
      });
  }, [toast, cb]);

  return (
    <div className={css.wrapper}>
      <TopBar />
      <PuzzleArea />
      <Keyboard />
    </div>
  );
};

export default Kilordle;
