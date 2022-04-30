import React from "react";
import css from "./errors.module.css";
import cx from "classnames";
import create from "zustand";

type AddToast = (color: ToastColor, text: string, timeout?: number) => void;

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

interface ToastState {
  toasts: ToastData[];
  toastId: number;
  addToast: AddToast;
}

const useStore = create<ToastState>((set) => {
  function popToast() {
    set((state) => ({
      toasts: state.toasts.slice(1),
      toastId: state.toastId + 1,
    }));
  }

  function addToast(color: ToastColor, text: string, timeout?: number) {
    set((state) => ({
      toasts: [...state.toasts, { color: ColorMap[color], text }],
    }));

    setTimeout(popToast, timeout ?? 3 * 1000);
  }

  return {
    toasts: [],
    toastId: 0,
    addToast,
  };
});

const getToasts = (state: ToastState) => state.toasts;
const getToastId = (state: ToastState) => state.toastId;
const getAddToast = (state: ToastState) => state.addToast;

export function useAddToast(): AddToast {
  const addToast = useStore(getAddToast);

  return addToast;
}

export const ToastCorner: React.VFC = () => {
  const toasts = useStore(getToasts);
  const toastId = useStore(getToastId);

  return (
    <div className={css.toastCorner}>
      {toasts.map(({ color, text }, idx) => {
        return (
          <div key={idx + toastId} className={cx(css.toast, color)}>
            {text}
          </div>
        );
      })}
    </div>
  );
};
