import React from "react";
import type { Dispatch, SetStateAction } from "react";
import css from "./kilordle.module.css";
import * as wasm from "components/wasm";
import cx from "classnames";
import create from "zustand";
import { useToast, ToastColors } from "components/errors";

interface ShapesCb {}

interface ShapesState {
  callbacks: ShapesCb;
}

const wasmRef: wasm.WasmRef = wasm.ref();

const useStore = create<ShapesState>((set, get) => {
  return {
    callbacks: {},
  };
});

const Shapes: React.VFC = () => {
  return null;
};

export default Shapes;
