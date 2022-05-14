import React from "react";
import css from "./errors.module.css";
import cx from "classnames";
import create from "zustand";

type AddToast = (kind: ToastColor, time: number | null, ...t: string[]) => void;

type ToastColor =
  | "red"
  | "green"
  | "orange"
  | "blue"
  | "error"
  | "warn"
  | "info"
  | "log"
  | "success";

export const ToastColors: Record<string, ToastColor> = {
  red: "red",
  green: "green",
  blue: "blue",
  orange: "orange",
  error: "red",
  info: "info",
  log: "log",
  success: "success",
  warn: "warn",
};

const ColorMap: Record<ToastColor, string> = {
  red: css.red,
  green: css.green,
  blue: css.blue,
  orange: css.orange,
  error: css.red,
  info: css.blue,
  log: css.blue,
  success: css.green,
  warn: css.orange,
};

interface ToastData {
  color: string;
  text: string;
}

interface ToastCallbacks {
  add: AddToast;
}

// Use Map here, which iterates in insertion order
interface ToastState {
  toasts: ToastData[];
  toastId: number;
  cb: ToastCallbacks;
}

const useStore = create<ToastState>((set) => {
  function popToast(count: number) {
    // TODO bounds check?
    set((state) => ({
      toasts: state.toasts.slice(count),
      toastId: state.toastId + count,
    }));
  }

  function add(kind: ToastColor, time: number | null, ...toasts: string[]) {
    const color = ColorMap[kind];
    set((state) => ({
      toasts: [...state.toasts, ...toasts.map((text) => ({ color, text }))],
    }));

    setTimeout(() => popToast(toasts.length), time ?? 3 * 1000);
  }

  return {
    toasts: [],
    toastId: 0,
    cb: {
      add,
    },
  };
});

const getToasts = (state: ToastState) => state.toasts;
const getToastId = (state: ToastState) => state.toastId;
const getCallbacks = (state: ToastState): ToastCallbacks => state.cb;

export const useToastStore = useStore;

export function useToast(): ToastCallbacks {
  const cb = useStore(getCallbacks);

  return cb;
}

export const ToastCorner: React.VFC = () => {
  const toasts = useStore(getToasts);
  const toastId = useStore(getToastId);

  return (
    <div className={css.toastCorner}>
      <div className={css.toastContent}>
        {toasts.map(({ color, text }, idx) => {
          return (
            <div key={idx + toastId} className={cx(css.toast, color)}>
              {text}
            </div>
          );
        })}
      </div>
    </div>
  );
};

export const postToast = (tag: string, data: any): void => {
  const toast = useStore.getState().cb;

  console.log(tag, data);

  if (typeof data === "string") {
    toast.add(ToastColors[tag] ?? "green", null, data);
  }
};
