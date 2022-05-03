import React from "react";
import type { Dispatch, SetStateAction } from "react";
import css from "./kilordle.module.css";
import * as wasm from "components/wasm";
import cx from "classnames";
import create from "zustand";

interface ShapesCb {
  setWasmRef: (wasmRef: wasm.Ref) => void;
}

interface ShapesState {
  wasmRef: wasm.Ref | undefined;
  callbacks: ShapesCb;
}

const useStore = create<ShapesState>((set, get) => {
  const setWasmRef = (wasmRef: wasm.Ref) => set({ wasmRef });

  return {
    wasmRef: undefined,
    callbacks: {
      setWasmRef,
    },
  };
});

const Shapes: React.VFC = () => {
  const cb = useStore((state) => state.callbacks);
  const wasmRef = useStore((state) => state.wasmRef);
  const [text, setText] = React.useState("");

  React.useEffect(() => {
    const wasmPromise = wasm.fetchWasm("/assets/shapes.wasm", {
      postMessage: wasm.postToast,
      imports: {},
      raw: {},
    });

    wasmPromise.then((ref) => {
      ref.abi.init();
      cb.setWasmRef(ref);
    });
  }, [cb]);

  return (
    <form
      onSubmit={(evt) => {
        evt.preventDefault();

        if (!wasmRef) return;

        const idx = wasmRef.addObj(text);
        wasmRef.defer.print(idx);
      }}
    >
      <label>
        Name:
        <input
          type="text"
          value={text}
          onChange={(evt) => setText(evt.target.value)}
        />
      </label>
      <input type="submit" value="Submit" />
    </form>
  );
};

export default Shapes;
