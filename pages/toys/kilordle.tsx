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
  clearError: () => void;
}

interface KilordleState {
  foundLetters: Record<string, true>;
  submissionCount: number;
  wordsLeft: number;
  submitError: boolean;
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
  const addChar = (c: string) => {
    const word = get().word;
    if (word.length > 4) {
      return;
    }

    set({ word: word + c.toLowerCase(), submitError: false });
  };

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
        set({ submitError: true });
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
        set({
          foundLetters: { ...foundLetters, ...newFounds },
        });
      }

      set({
        word: "",
        submissionCount: submissionCount + 1,
        submitError: false,
      });
    });
  };

  const setPuzzles = (puzzles: PuzzleWasmData[]) => {
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

  const clearError = () => set({ submitError: false });

  return {
    word: "",
    submissionCount: 0,
    submitError: false,
    wordsLeft: 0,
    foundLetters: {},
    puzzles: [],
    callbacks: {
      submit,
      addChar,
      deleteChar,
      setPuzzles,
      setWordsLeft,
      clearError,
    },
  };
});

const TopBar: React.VFC = () => {
  const word = useStore((state) => state.word.toUpperCase());
  const submitError = useStore((state) => state.submitError);
  const submissionCount = useStore((state) => state.submissionCount);
  const wordsLeft = useStore((state) => state.wordsLeft);
  const cb = useStore((state) => state.callbacks);

  const timeoutRef = React.useRef<any>();

  React.useEffect(() => {
    clearTimeout(timeoutRef.current);
    timeoutRef.current = undefined;

    if (submitError) {
      timeoutRef.current = setTimeout(() => cb.clearError(), 1000);
    }
  }, [cb, submitError]);

  return (
    <div className={css.topBar}>
      <div></div>

      <div className={cx(css.submitWindow, submitError && css.shake)}>
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
          const lower = letter.toLowerCase();
          const isLower = letter === lower;

          // We use the isLower test here instead of checking against space
          // so that in debug builds we can see the actual solution and
          // double-check that everything is kosher. This logic ensures that
          // lowercase letters and space are output as white and uppercase
          // are green.
          return (
            <div key={idx} className={cx(css.letterBox, isLower || css.green)}>
              {letter.toUpperCase()}
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
  const wordsLeft = useStore((state) => state.wordsLeft);
  const submissionCount = useStore((state) => state.submissionCount);

  if (submissionCount === 0) {
    return (
      <div className={css.centerMessage}>
        {"No submissions yet. Try typing a word and hitting 'Enter'!"}
      </div>
    );
  }

  if (wordsLeft === 0) {
    return (
      <div className={css.centerMessage}>
        {"You won! Refresh to play again."}
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
