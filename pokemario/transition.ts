import { assertType } from "./utils";
import { State } from "zustand";

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

export class TransitionManager {
  transitions: StatefulTransition<Record<string, number>>[] = [];

  isTransitionComplete(transition: StatefulTransition<Record<string, number>>) {
    for (const key of Object.keys(transition.target)) {
      const reachedTarget =
        (transition.target[key] >= transition.initial[key] &&
          transition.state[key] >= transition.target[key]) ||
        (transition.target[key] < transition.initial[key] &&
          transition.state[key] <= transition.target[key]);
      if (!reachedTarget) {
        return false;
      }
    }
    return true;
  }

  reset() {
    this.transitions = [];
  }

  addTransition<T>(transition: Transition<{ [key in keyof T]: number }>) {
    this.transitions.push({
      ...transition,
      state: { ...transition.initial },
    } as any);
  }

  applyTransition<T>(
    t: StatefulTransition<{ [key in keyof T]: number }>,
    delta: number
  ) {
    for (const key of Object.keys(t.target)) {
      t.transition(key, t, delta);
    }
    return t.state;
  }

  tick(delta: number) {
    this.transitions = this.transitions.flatMap((t) => {
      if (this.isTransitionComplete(t)) {
        t.update(t.target);
        return [];
      }

      for (const key of Object.keys(t.target)) {
        t.transition(key, t, delta);
      }
      t.update(t.state);

      return [t];
    });
  }
}
