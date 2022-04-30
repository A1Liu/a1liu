import React from "react";
import css from "./errors.module.css";
import create from "zustand";

type AddToast = (text: string, timeout?: number) => void;

interface ToastState {
  toasts: string[];
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

  function addToast(text: string, timeout?: number) {
    set((state) => ({
      toasts: [...state.toasts, text],
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
      {toasts.map((text, idx) => {
        return (
          <div key={idx + toastId} className={css.toast}>
            {text}
          </div>
        );
      })}
    </div>
  );
};
