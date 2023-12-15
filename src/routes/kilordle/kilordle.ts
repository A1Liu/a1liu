import WordleWordsString from "./wordle-words.txt";
import WordlesString from "./wordles.txt";

// Uppercase means the output text should be orange.
export interface PuzzleData {
  solution: string;
  filled: string;
  submits: string;
}

const WordleDictionary = new Set(WordleWordsString.trim().split(/\s+/));

type Match =
  | { kind: "none" }
  | { kind: "exact" }
  | { kind: "letter"; index: number };

interface MatchResult {
  matches: Match[];
  score: number;
}
export function matchWordle(wordle: string, submission: string): MatchResult {
  return {
    matches: [],
    score: 1,
  };
}

class Worlde {
  private remainingWordlesList: string[] = WordlesString.trim().split(/\s+/);
  private recentSubmissions: string[] = [];
  private readonly positionLetterDicts = [
    new Set<string>(),
    new Set<string>(),
    new Set<string>(),
    new Set<string>(),
    new Set<string>(),
  ] as const;
  readonly letterDict = new Set<string>();

  constructor() {}

  submitWord(word: string): boolean {
    if (!WordleDictionary.has(word)) return false;

    [...word].forEach((letter, index) => {
      this.positionLetterDicts[index]?.add(letter);
      this.letterDict.add(letter);
    });

    this.remainingWordlesList = this.remainingWordlesList.filter((wordle) =>
      [...wordle].some(
        (letter, index) => !this.positionLetterDicts[index]?.has(letter)
      )
    );

    this.recentSubmissions = [...this.recentSubmissions.slice(-4), word];

    return true;
  }

  puzzleHint(puzzle: string): PuzzleData {
    const matches = [...puzzle].map((letter, index): Match => {
      switch (this.positionLetterDicts[index]?.has(letter)) {
        case true: {
          return { kind: "exact" };
        }
        case false:
        case undefined: {
          if (this.letterDict.has(letter)) return { kind: "letter", index };
          return { kind: "none" };
        }
      }
    });

    matchWordle(puzzle, submission);
  }

  get puzzles(): string[] {
    return this.remainingWordlesList;
  }
}
