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
  const increment = React.useCallback(
    () => setCounter((c) => ++c),
    [setCounter]
  );

  return [counter, increment];
}
