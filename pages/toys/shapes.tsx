import React from "react";
import type { Dispatch, SetStateAction } from "react";
import css from "./kilordle.module.css";
import * as wasm from "components/wasm";
import cx from "classnames";
import create from "zustand";
import { useToast, ToastColors } from "components/errors";

interface ShapesCb {
  setWasmRef: (wasmRef: WasmRef) => void;
}

interface ShapesState {
  wasmRef: WasmRef | undefined;
  callbacks: ShapesCb;
}

const useStore = create<ShapesState>((set, get) => {
  const setWasmRef = (wasmRef: WasmRef) => set({ wasmRef });

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
  const toast = useToast();

  React.useEffect(() => {
    const postMessage = (tag: string, data: any) => {
      console.log(tag, data);

      if (typeof data === "string") {
        toast.add(ToastColors[tag] ?? "green", null, data);
      }
    };

    const wasmPromise = wasm.fetchWasm("/assets/shapes.wasm", {
      postMessage,
      imports: {},
      raw: {},
    });

    wasmPromise.then((ref) => {
      ref.abi.init();
      cb.setWasmRef(ref);
    });
  }, [toast, cb]);

  return (
    <form
      onSubmit={(evt) => {
        evt.preventDefault();

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
