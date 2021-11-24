import React, {
  useState,
  useRef,
  useCallback,
  useMemo,
  useEffect,
} from "react";

export const timeout = (ms: number): Promise<void> =>
  new Promise((res) => setTimeout(res, ms));

export type AsyncValueMissing<T> = {
  readonly refetch: () => void;
  readonly isLoaded: false;
  readonly isLoading: boolean;
  readonly data: null;
  readonly error: any | null;
};

export type AsyncValueLoaded<T> = {
  readonly refetch: () => void;
  readonly isLoaded: true;
  readonly isLoading: boolean;
  readonly data: T;
  readonly error: null;
};

export type AsyncValue<T> = AsyncValueLoaded<T> | AsyncValueMissing<T>;

export function useAsync<T>(
  _fn: () => Promise<T>,
  deps: any[] = []
): AsyncValue<T> {
  const [_, fetchFinished] = useState(0);
  const [fetches, incFetch] = useState(0);
  const started = useRef(0);
  const done = useRef(0);
  const data = useRef<T | null>(null);
  const error = useRef<any | null>(null);

  const refetch = useCallback(() => incFetch((s) => ++s % 4096), [incFetch]);

  // Missing the _fn dependency so that the callback only changes when the provided
  // deps change.
  //
  // eslint-disable-next-line react-hooks/exhaustive-deps
  const fn = useCallback(_fn, deps);


  // Extra dependencies here allow us to force a refetch when someone calls
  // refetch.
  //
  // eslint-disable-next-line react-hooks/exhaustive-deps
  const index = useMemo(() => ++started.current, [started, fn, fetches]);

  useEffect(() => {
    let mounted = true;

    const doCall = async () => {
      let newValue = null;
      let newError = null;

      await fn()
        .then((v) => (newValue = v))
        .catch((e) => (newError = e));

      if (mounted && done.current < index) {
        done.current = index;
        data.current = newValue;
        error.current = newError;
        fetchFinished((s) => (s + 1) % 4096);
      }
    };

    doCall();

    return () => {
      mounted = false;
    };
  }, [fn, index, data, error, done, fetchFinished]);

  if (error.current === null && done.current > 0) {
    return {
      refetch,
      isLoaded: true,
      isLoading: index > done.current,
      data: data.current!,
      error: null,
    };
  }

  return {
    refetch,
    isLoaded: false,
    isLoading: index > done.current,
    data: null,
    error: error.current,
  };
}
