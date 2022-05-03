import React from "react";
import type { Dispatch, SetStateAction } from "react";
import css from "./grapher.module.css";
import * as wasm from "components/wasm";
import { useToast } from "components/errors";
import cx from "classnames";
import create from "zustand";

type WebGl = WebGL2RenderingContext;

interface GrapherCb {
  initWasm: (wasmRef: wasm.Ref) => void;
  initGl: (gl: WebGL) => void;
}

interface GrapherState {
  gl: WebGL | null;
  wasmRef: wasm.Ref | null;
  callbacks: GrapherCb;
}

const useStore = create<GrapherState>((set, get) => {
  const initWasm = (wasmRef: wasm.Ref) => set({ wasmRef });
  const initGl = (gl: WebGL) => set({ gl });
  return {
    glContext: null,
    wasmRef: null,
    callbacks: {
      initWasm,
      initGl,
    },
  };
});

const Grapher: React.VFC = () => {
  const cb = useStore((state) => state.callbacks);
  const wasmRef = useStore((state) => state.wasmRef);
  const [text, setText] = React.useState("");
  const canvasRef = React.useRef<HTMLCanvasElement>(null);
  const toast = useToast();

  React.useEffect(() => {
    const gl = canvasRef.current.getContext("webgl2");
    if (!gl) {
      toast.add("error", null, "WebGL2 not supported!");
    } else {
      toast.add("success", null, "WebGL2 context initialized!");
    }

    cb.initGl(gl);
  }, [canvasRef, toast, cb]);

  React.useEffect(() => {
    const wasmPromise = wasm.fetchWasm("/assets/grapher.wasm", {
      postMessage: wasm.postToast,
      imports: {},
      raw: {},
    });

    wasmPromise.then((ref) => {
      ref.abi.init();
      cb.initWasm(ref);
    });
  }, [cb]);

  return (
    <div className={css.wrapper}>
      <form
        onSubmit={(evt) => {
          evt.preventDefault();

          if (!wasmRef) return;

          const idx = wasmRef.addObj(text);
          wasmRef.abi.print(idx);
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

      <canvas ref={canvasRef} className={css.canvas} />
    </div>
  );
};

export default Grapher;
