import React from "react";
import Link from "next/link";
import shallow from "zustand/shallow";
import type { Number3, Message, OutMessage } from "src/erlang.worker";
import type { Dispatch, SetStateAction } from "react";
import * as GL from "src/webgl";
import type { WebGl } from "src/webgl";
import styles from "./erlang.module.css";
import css from "src/tsx/util.module.css";
import * as wasm from "src/wasm";
import { useToast, ToastColors } from "src/tsx/errors";
import cx from "classnames";
import create from "zustand";

interface ErlangCb {
  initWorker: (workerRef: Worker) => void;
}

interface ErlangState {
  workerRef: Worker | null;

  cb: ErlangCb;
}

const useStore = create<ErlangState>((set, get) => {
  const initWorker = (workerRef: Worker) => set({ workerRef });

  return {
    workerRef: null,

    cb: {
      initWorker,
    },
  };
});

const selectStable = ({ cb, workerRef }: ErlangState) => ({ cb, workerRef });
const useStable = (): Pick<ErlangState, "cb" | "workerRef"> => {
  return useStore(selectStable, shallow);
};

const Erlang: React.VFC = () => {
  const { cb, workerRef } = useStable();
  const toast = useToast();

  const canvasRef = React.useRef<HTMLCanvasElement>(null);

  React.useEffect(() => {
    if (!workerRef) return;

    const listener = (evt: any) => {
      const canvas = canvasRef.current;
      if (!canvas) return;

      const width = canvas.clientWidth;
      const height = canvas.clientHeight;
      workerRef.postMessage({ kind: "resize", data: [width, height] });
    };

    window.addEventListener("resize", listener);

    return () => window.removeEventListener("resize", listener);
  }, [canvasRef, workerRef]);

  React.useEffect(() => {
    // Writing this in a different way doesn't work. URL constructor call
    // must be passed directly to worker constructor.
    const worker = new Worker(new URL("src/erlang.worker.ts", import.meta.url));

    worker.onmessage = (ev: MessageEvent<OutMessage>) => {
      const message = ev.data;
      switch (message.kind) {
        case "initDone":
          const canvas = canvasRef.current!;
          const width = canvas.clientWidth;
          const height = canvas.clientHeight;
          worker.postMessage({ kind: "resize", data: [width, height] });
          break;

        default:
          if (typeof message.data === "string") {
            const color = ToastColors[message.kind] ?? "info";
            toast.add(color, null, message.data);
          }

          console.log(message.data);
          break;
      }
    };

    cb.initWorker(worker);
  }, [cb, toast]);

  React.useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas || !workerRef) return;

    const offscreen = (canvas as any).transferControlToOffscreen();
    workerRef.postMessage({ kind: "canvas", offscreen }, [offscreen]);
  }, [workerRef, canvasRef]);

  return (
    <div
      className={styles.wrapper}
      onMouseMove={(evt: React.MouseEvent) => {
        if (!canvasRef.current) return;
        if (evt.target !== canvasRef.current) return;

        const data = [evt.clientX, evt.clientY];
        workerRef?.postMessage({ kind: "mousemove", data });
      }}
      onClick={(evt: React.MouseEvent) => {
        if (!canvasRef.current) return;
        if (evt.target !== canvasRef.current) return;

        const data = [evt.clientX, evt.clientY];
        workerRef?.postMessage({ kind: "leftclick", data });
      }}
      onContextMenu={(evt: React.MouseEvent) => {
        if (!canvasRef.current) return;
        if (evt.target !== canvasRef.current) return;

        evt.preventDefault();

        const data = [evt.clientX, evt.clientY];
        workerRef?.postMessage({ kind: "rightclick", data });
      }}
      onKeyDown={(evt: any) => {
        if (evt.repeat || evt.isComposing || evt.keyCode === 229) return;

        if (!canvasRef.current) return;
        if (evt.target !== canvasRef.current) return;

        workerRef?.postMessage({ kind: "keydown", data: evt.keyCode });
      }}
      onKeyUp={(evt: any) => {
        if (evt.isComposing || evt.keyCode === 229) return;

        if (!canvasRef.current) return;
        if (evt.target !== canvasRef.current) return;

        workerRef?.postMessage({ kind: "keyup", data: evt.keyCode });
      }}
    >
      <canvas
        ref={canvasRef}
        className={styles.canvas}
        contentEditable
        onDoubleClick={(evt) => {
          evt.stopPropagation();
          evt.preventDefault();
        }}
      />
    </div>
  );
};

export default Erlang;
