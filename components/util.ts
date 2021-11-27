import React, {
  useState,
  useRef,
  useCallback,
  useMemo,
  useEffect,
} from "react";
import fsPromise from 'fs/promises';

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

function useAsyncHelper<T>(
  fn: () => Promise<T>,
  _deps: any[] | null
): AsyncValue<T> {
  const [fetches, incFetch] = useState(0);

  const [active, setActive] = useState(0);
  const startedRef = useRef(0);
  const doneRef = useRef(0);

  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState<any | null>(null);

  const refetch = useCallback(() => incFetch((s) => s + 1), [incFetch]);
  const deps = [fetches].concat(_deps ?? []);

  // Intentionally removing most stuff from the dependencies. This effect should
  // only trigger when the dependencies change or when the refetch is called.
  /* eslint-disable */
  useEffect(() => {
    const started = startedRef.current++;
    if (_deps === null && started === 0) return;

    let mounted = true;

    const doCall = async () => {
      let newValue = null;
      let newError = null;

      setActive((a) => a + 1);

      await fn()
        .then((v) => (newValue = v))
        .catch((e) => (newError = e));

      setActive((a) => a - 1);

      if (mounted && doneRef.current <= started) {
        doneRef.current = started + 1;
        setData(newValue);
        setError(newError);
      }
    };

    doCall();

    return () => {
      mounted = false;
    };
  }, deps);
  /* eslint-enable */

  if (error === null && doneRef.current > 0) {
    return {
      refetch,
      isLoaded: true,
      isLoading: active > 0,
      data: data!,
      error: null,
    };
  }

  return {
    refetch,
    isLoaded: false,
    isLoading: active > 0,
    data: null,
    error: error,
  };
}

export function useAsyncLazy<T>(fn: () => Promise<T>): AsyncValue<T> {
  return useAsyncHelper(fn, null);
}

export function useAsync<T>(
  fn: () => Promise<T>,
  deps: any[] = []
): AsyncValue<T> {
  return useAsyncHelper(fn, deps);
}
