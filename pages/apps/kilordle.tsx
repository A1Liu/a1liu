import React from "react";
import Head from "next/head";
import type { Dispatch, SetStateAction } from "react";
import styles from "./kilordle.module.css";
import css from "src/tsx/util.module.css";
import * as wasm from "src/wasm";
import { postToast } from "src/tsx/errors";
import { defer } from "src/util";
import cx from "classnames";
import create from "zustand";

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
  setWasmRef: (wasmRef: wasm.Ref) => void;
  reset: () => void;
  clearError: () => void;
  incrementSubmissionCount: () => void;
  resetSubmission: () => void;
}

interface KilordleState {
  wasmRef: wasm.Ref | undefined;
  foundLetters: Record<string, true>;
  submissionCount: number;
  wordsLeft: number;
  submitError: boolean;
  word: string;
  puzzles: PuzzleData[];
  callbacks: KilordleCb;
}

// https://github.com/vercel/next.js/tree/canary/examples/with-web-worker

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
    const { word, foundLetters, submissionCount, wasmRef } = get();

    if (word.length < 5) return;
    if (!wasmRef) return;

    const chars = word.split("");
    const codes = chars.map((c) => c.charCodeAt(0));

    defer(() => {
      if (!wasmRef.abi.submitWord(...codes)) {
        set({ submitError: true });
        return;
      }

      const newFounds: Record<string, true> = {};
      chars.forEach((letter) => {
        newFounds[letter] = true;
      });

      set({ foundLetters: { ...foundLetters, ...newFounds } });
    });
  };

  const incrementSubmissionCount = (): void =>
    set((state) => ({ submissionCount: state.submissionCount + 1 }));

  const resetSubmission = (): void => {
    set({
      word: "",
      submitError: false,
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

  const setWasmRef = (wasmRef: wasm.Ref) => set({ wasmRef });

  const reset = (): void => {
    const { wasmRef } = get();
    if (!wasmRef) return;

    wasmRef.abi.reset();

    set({
      word: "",
      submissionCount: 0,
      submitError: false,
      puzzles: [],
      foundLetters: {},
    });
  };

  return {
    word: "",
    wasmRef: undefined,
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
      setWasmRef,
      reset,
      incrementSubmissionCount,
      resetSubmission,
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
    <div className={styles.topBar}>
      <div className={cx(styles.submitWindow, submitError && styles.shake)}>
        <div className={styles.letterBox}>{word[0]}</div>
        <div className={styles.letterBox}>{word[1]}</div>
        <div className={styles.letterBox}>{word[2]}</div>
        <div className={styles.letterBox}>{word[3]}</div>
        <div className={styles.letterBox}>{word[4]}</div>
      </div>

      <div className={styles.statsBox}>
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
    <div ref={keyboardRef} className={styles.keyboard}>
      {KEYROWS.map((row, idx) => {
        return (
          <div
            key={idx}
            className={cx(styles.keyboardRow, idx === 1 && styles.middleRow)}
          >
            {row.map((key) => {
              return (
                <button
                  key={key}
                  className={cx(
                    styles.keyBox,
                    foundLetters[key] && styles.gray
                  )}
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
    <div className={styles.puzzle}>
      <div className={styles.filledBox}>
        {puzzle.filled.split("").map((letter, idx) => {
          const lower = letter.toLowerCase();
          const isLower = letter === lower;

          // We use the isLower test here instead of checking against space
          // so that in debug builds we can see the actual solution and
          // double-check that everything is kosher. This logic ensures that
          // lowercase letters and space are output as white and uppercase
          // are green.
          return (
            <div
              key={idx}
              className={cx(styles.letterBox, isLower || styles.green)}
            >
              {letter.toUpperCase()}
            </div>
          );
        })}
      </div>

      {puzzle.submits.map((submit) => (
        <div key={submit} className={styles.submitBox}>
          {submit.split("").map((letter, idx) => {
            const upper = letter.toUpperCase();
            const isUpper = letter === upper;

            return (
              <div
                key={idx}
                className={cx(styles.letterBox, isUpper && styles.yellow)}
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
  const cb = useStore((state) => state.callbacks);
  const puzzles = useStore((state) => state.puzzles);
  const wordsLeft = useStore((state) => state.wordsLeft);
  const submissionCount = useStore((state) => state.submissionCount);

  if (submissionCount === 0) {
    return (
      <div className={styles.centerMessage}>
        {"No submissions yet. Try typing a word and hitting 'Enter'!"}
      </div>
    );
  }

  if (wordsLeft === 0) {
    return (
      <div className={styles.centerMessage}>
        <p>{"You won!"}</p>
        <button className={css.muiButton} onClick={cb.reset}>
          Play again
        </button>
      </div>
    );
  }

  return (
    <div className={styles.guessesArea}>
      {puzzles.map((puzzle) => (
        <Puzzle key={puzzle.solution} puzzle={puzzle} />
      ))}
    </div>
  );
};

export const Kilordle: React.VFC = () => {
  const cb = useStore((state) => state.callbacks);

  React.useEffect(() => {
    const wasmRef = wasm.fetchWasm("/apps/kilordle.wasm", {
      postMessage: postToast,
      imports: { setPuzzles: cb.setPuzzles },
      raw: () => ({
        resetSubmission: cb.resetSubmission,
        incrementSubmissionCount: cb.incrementSubmissionCount,
        setWordsLeft: cb.setWordsLeft,
        addChar: (code: number) => {
          const character = String.fromCharCode(code);
          cb.addChar(character);
        },
      }),
    });

    const wordles = wasm.fetchAsset("/apps/wordles.txt");
    const words = wasm.fetchAsset("/apps/wordle-words.txt");

    Promise.all([wasmRef, wordles, words]).then(([ref, wordles, words]) => {
      const wordlesId = ref.addObj(wordles);
      const wordsId = ref.addObj(words);

      ref.abi.init(wordlesId, wordsId);
      cb.setWasmRef(ref);
    });
  }, [cb]);

  return (
    <div className={styles.wrapper}>
      <Head>
        <link key="pwa-link" rel="manifest" href="/apps/kilordle.webmanifest" />

        <meta key="theme-color" name="theme-color" content="#1976D2" />
      </Head>

      <TopBar />
      <div className={styles.centerArea}>
        <PuzzleArea />
      </div>
      <Keyboard />
    </div>
  );
};

export default Kilordle;
