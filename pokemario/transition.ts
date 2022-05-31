import { assertType } from "./utils";

type TransitionStepFunc = (
  property: string,
  transition: StatefulTransition<Record<string, number>>,
  delta: number
) => void;

export const Transitions = {
  linear:
    (duration: number) =>
    (
      property: string,
      transition: StatefulTransition<Record<string, number>>,
      delta: number
    ) => {
      const stepSize =
        (transition.target[property] - transition.initial[property]) / duration;
      transition.state[property] += stepSize * delta;
    },
} as const;

assertType<Record<string, (...args: any[]) => TransitionStepFunc>>(Transitions);

export interface Transition<T extends { [key: string]: number }> {
  initial: T;
  target: T;
  transition: TransitionStepFunc;
  update: (state: T) => void;
}

type StatefulTransition<T extends { [key: string]: number }> = Transition<T> & {
  state: T;
};

export function applyTransition<T>(
  _t: StatefulTransition<{ [key in keyof T]: number }>,
  delta: number
) {
  const t = _t as any as StatefulTransition<Record<string, number>>;

  for (const key of Object.keys(t.target)) {
    const initialValue = t.initial[key];
    const currentValue = t.state[key];
    const targetValue = t.target[key];

    if (
      (initialValue <= targetValue && currentValue >= targetValue) ||
      (initialValue > targetValue && currentValue < targetValue)
    ) {
      t.state[key] = targetValue;
    } else {
      t.transition(key, t, delta);
    }
  }
  return _t.state;
}
