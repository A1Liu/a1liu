import React from "react";
import Link from "next/link";
import shallow from "zustand/shallow";
import type { Number3, Message, OutMessage } from "src/painter.worker";
import type { Dispatch, SetStateAction } from "react";
import * as GL from "components/webgl";
import type { WebGl } from "components/webgl";
import styles from "./painter.module.css";
import css from "components/util.module.css";
import * as wasm from "components/wasm";
import { useToast, ToastColors } from "components/errors";
import cx from "classnames";
import create from "zustand";

type String3 = [string, string, string];

interface PainterCb {
  initWorker: (workerRef: Worker) => void;
  setIsRecording: (isRecording: boolean) => void;
  setRecordingUrl: (url: string) => void;
  setTool: (url: string) => void;
  setColor: (setter: (color: Number3) => Number3) => void;
  setColorText: (setter: (color: String3) => String3) => void;
}

interface PainterState {
  workerRef: Worker | null;

  color: Number3;
  colorText: String3;
  tool: string;
  isRecording: boolean;
  recordingUrl: string | null;

  cb: PainterCb;
}

const useStore = create<PainterState>((set, get) => {
  const initWorker = (workerRef: Worker) => set({ workerRef });
  const setIsRecording = (isRecording: boolean): void => set({ isRecording });
  const setRecordingUrl = (recordingUrl: string): void => set({ recordingUrl });
  const setTool = (tool: string): void => set({ tool });
  const setColor = (setter: (color: Number3) => Number3): void => {
    const { color } = get();
    set({ color: setter(color) });
  };
  const setColorText = (setter: (color: String3) => String3): void => {
    const { colorText } = get();
    set({ colorText: setter(colorText) });
  };

  return {
    isRecording: false,
    recordingUrl: null,
    workerRef: null,

    color: [0.5, 0.5, 0.5],
    colorText: ["0.5", "0.5", "0.5"],
    tool: "triangle",

    cb: {
      initWorker,
      setIsRecording,
      setRecordingUrl,
      setTool,
      setColor,
      setColorText,
    },
  };
});

const selectStable = ({ cb, workerRef }: PainterState) => ({ cb, workerRef });
const useStable = (): Pick<PainterState, "cb" | "workerRef"> => {
  return useStore(selectStable, shallow);
};

interface FloatInputProps {
  index: number;
  data: number;
}

const FloatInput: React.VFC<FloatInputProps> = ({ index, data }) => {
  const { cb } = useStable();
  const text = useStore((state) => state.colorText[index]);
  const [error, setError] = React.useState(false);
  const paletteRef = React.useRef<HTMLDivElement>(null);

  const color = useStore((state) => state.color);

  React.useEffect(() => {
    const val = Number.parseFloat(text);

    const valIsInvalid = isNaN(val);
    setError(valIsInvalid);

    if (valIsInvalid) return;

    cb.setColor((color) => {
      const newVal: Number3 = [...color];
      newVal[index] = val;

      return newVal;
    });
  }, [text, setError, index, cb]);

  const setText = (val: string) =>
    cb.setColorText((prev: String3): String3 => {
      const newVal: String3 = [...prev];
      newVal[index] = val;

      return newVal;
    });

  return (
    <div className={styles.floatInWrapper}>
      {`${"RGB"[index]}: `}
      <input
        className={styles.floatInInput}
        value={text}
        onChange={(evt) => setText(evt.target.value)}
      />

      {error && (
        <button
          className={styles.floatInButton}
          onClick={() => setText(`${data}`)}
        >
          reset
        </button>
      )}
    </div>
  );
};

const Config: React.VFC = () => {
  const { cb, workerRef } = useStable();
  const isRecording = useStore((state) => state.isRecording);
  const recordingUrl = useStore((state) => state.recordingUrl);
  const color = useStore((state) => state.color);
  const tool = useStore((state) => state.tool);

  const toast = useToast();

  const paletteRef = React.useRef<HTMLDivElement>(null);

  React.useEffect(() => {
    if (recordingUrl === null) return;

    return () => URL.revokeObjectURL(recordingUrl);
  }, [recordingUrl]);

  const [r, g, b] = color;

  React.useEffect(() => {
    if (!paletteRef.current) return;
    if (!workerRef) return;

    const colorStyle = `rgb(${r * 255}, ${g * 255}, ${b * 255})`;
    paletteRef.current.style.backgroundColor = colorStyle;
    workerRef.postMessage({ kind: "setColor", data: [r, g, b] });
  }, [paletteRef, workerRef, r, g, b]);

  let urlString = "https://github.com/A1Liu/a1liu/issues/new";
  const query = { title: "Painter: Bug Report", body: "" };
  const queryString = new URLSearchParams(query).toString();
  if (queryString) {
    urlString += "?" + queryString;
  }

  return (
    <div className={styles.configBox}>
      <div className={styles.config}>
        <h3>Painter</h3>

        <button
          className={css.muiButton}
          onClick={() => workerRef?.postMessage({ kind: "toggleTool" })}
        >
          {tool}
        </button>

        <div className={styles.colorPicker}>
          <div ref={paletteRef} className={styles.palette} />

          <div className={styles.colorValues}>
            <FloatInput index={0} data={r} />

            <FloatInput index={1} data={g} />

            <FloatInput index={2} data={b} />
          </div>
        </div>

        <div className={styles.configRow}>
          <button
            className={css.muiButton}
            onClick={() => {
              if (navigator.userAgent.indexOf("Firefox") != -1) {
                toast.add(
                  "warn",
                  5 * 1000,
                  "Recording on Firefox isn't supported right now"
                );

                return;
              }

              cb.setIsRecording(!isRecording);
            }}
          >
            {isRecording ? "stop" : "record"}
          </button>

          {recordingUrl && (
            <button
              className={css.muiButton}
              onClick={() => {
                const a = document.createElement("a");
                a.href = recordingUrl;
                a.download = "recording.webm";
                a.click();
              }}
            >
              Download
            </button>
          )}
        </div>

        {recordingUrl && (
          <video controls autoPlay muted src={recordingUrl} width="100%">
            {"Sorry, your browser doesn't support embedded videos."}
          </video>
        )}
      </div>

      <a
        className={styles.bugReport}
        target="_blank"
        rel="noreferrer"
        href={urlString}
      >
        Report a bug
      </a>
    </div>
  );
};

const Painter: React.VFC = () => {
  const { cb, workerRef } = useStable();
  const isRecording = useStore((state) => state.isRecording);
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
    const worker = new Worker(
      new URL("src/painter.worker.ts", import.meta.url)
    );

    worker.onmessage = (ev: MessageEvent<OutMessage>) => {
      const message = ev.data;
      switch (message.kind) {
        case "setTool":
          cb.setTool(message.data);
          break;

        case "setColor":
          cb.setColor((color: Number3) => message.data);
          cb.setColorText((text: String3) =>
            message.data.map((v: any) => `${v}`)
          );
          break;

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

    if (!canvas) return;
    if (!isRecording) return;

    const stream = canvas.captureStream(24);
    const mediaRecorder = new MediaRecorder(stream);
    const recordedChunks: any[] = [];

    mediaRecorder.ondataavailable = (e) => {
      if (e.data.size > 0) recordedChunks.push(e.data);
    };

    mediaRecorder.onstop = (e) => {
      const blob = new Blob(recordedChunks, { type: "video/webm" });
      const url = URL.createObjectURL(blob);
      cb.setRecordingUrl(url);
    };

    mediaRecorder.start();

    return () => mediaRecorder.stop();
  }, [cb, isRecording, canvasRef]);

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
        if (evt.isComposing || evt.keyCode === 229) return;

        if (!canvasRef.current) return;
        if (evt.target !== canvasRef.current) return;

        workerRef?.postMessage({ kind: "keydown", data: evt.keyCode });
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

      <Config />
    </div>
  );
};

export default Painter;
