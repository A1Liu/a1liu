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
  setWordsLeft: (wordsLeft: number) => void;
}

interface KilordleState {
  foundLetters: Record<string, true>;
  submissionCount: number;
  wordsLeft: number;
  word: string;
  puzzles: PuzzleData[];
  callbacks: KilordleCb;
}

// https://github.com/vercel/next.js/tree/canary/examples/with-web-worker
const wasmRef: wasm.WasmRef = wasm.ref();

const KEYROWS = [
  "qwertyuiop".split(""),
  "asdfghjkl".split(""),
  ["Go", ..."zxcvbnm".split(""), "Del"],
];

const pressKey = (key: string, cb: KilordleCb): boolean => {
  switch (key) {
    case "Shift":
    case "Control":
    case " ":
      return false;

    case "Enter":
    case "Go":
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

      return { word: state.word + c.toLowerCase() };
    });

  const submit = () => {
    const state = get();
    const { word, foundLetters, submissionCount } = get();

    if (word.length < 5) {
      return;
    }

    const chars = word.split("");
    const codes = chars.map((c) => c.charCodeAt(0));

    wasmRef.defer.submitWord(...codes).then((success: boolean) => {
      if (!success) {
        return;
      }

      const newFounds: Record<string, true> = {};
      let foundCount = 0;

      chars.forEach((letter) => {
        if (!foundLetters[letter]) {
          newFounds[letter] = true;
          foundCount += 1;
        }
      });

      if (foundCount > 0) {
        set({ foundLetters: { ...foundLetters, ...newFounds } });
      }
    });

    set({ word: "", submissionCount: submissionCount + 1 });
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

  const setWordsLeft = (wordsLeft: number) => {
    set({ wordsLeft });
  };

  return {
    word: "",
    submissionCount: 0,
    wordsLeft: 0,
    foundLetters: {},
    puzzles: [],
    callbacks: { submit, addChar, deleteChar, setPuzzles, setWordsLeft },
  };
});

const TopBar: React.VFC = () => {
  const word = useStore((state) => state.word.toUpperCase());
  const submissionCount = useStore((state) => state.submissionCount);
  const wordsLeft = useStore((state) => state.wordsLeft);

  return (
    <div className={css.topBar}>
      <div></div>

      <div className={css.submitWindow}>
        <div className={css.letterBox}>{word[0]}</div>
        <div className={css.letterBox}>{word[1]}</div>
        <div className={css.letterBox}>{word[2]}</div>
        <div className={css.letterBox}>{word[3]}</div>
        <div className={css.letterBox}>{word[4]}</div>
      </div>

      <div className={css.statsBox}>
        <div>Guesses: {submissionCount}</div>
        <div>Words: {wordsLeft}</div>
      </div>
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

  if (puzzles.length === 0) {
    return (
      <div className={css.centerMessage}>
        {"No submissions yet. Try typing a word and hitting 'Enter'!"}
      </div>
    );
  }

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
        raw: { setWordsLeft: cb.setWordsLeft },
      })
      .then((ref) => {
        ref.abi.init();
      });
  }, [toast, cb]);

  return (
    <div className={css.wrapper}>
      <TopBar />
      <div className={css.centerArea}>
        <PuzzleArea />
      </div>
      <Keyboard />
    </div>
  );
};

export default Kilordle;
