import React from "react";

type Fn<Params extends any[], T extends object> = {
  (...args: Params): T;
};

export function makeStableHook<T extends object, Params extends any[]>(
  useValue: Fn<Params, T>
): Fn<Params, T> {
  return (...args: Params): T => {
    const result = useValue(...args);
    return useStable(result);
  };
}

export function useStable<T extends object>(o: T): T {
  return React.useMemo(() => o, Object.values(o)); // eslint-disable-line
}

export function useCounter(n: number): [number, () => void] {
  const [counter, setCounter] = React.useState(n);
  const increment = React.useCallback(() => setCounter(c => ++c), [setCounter]);

  return [counter, increment];
}

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
  const [fetches, setFetches] = React.useState(0);

  const [active, setActive] = React.useState(0);
  const startedRef = React.useRef(0);
  const doneRef = React.useRef(0);

  const [data, setData] = React.useState<T | null>(null);
  const [error, setError] = React.useState<any | null>(null);

  const refetch = React.useCallback(() => setFetches((s) => ++s), [setFetches]);
  const deps = [fetches].concat(_deps ?? []);

  // Intentionally removing most stuff from the dependencies. This effect should
  // only trigger when the dependencies change or when the refetch is called.
  /* eslint-disable */
  React.useEffect(() => {
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
