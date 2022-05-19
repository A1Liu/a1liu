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

interface PainterCb {
  initWorker: (workerRef: Worker) => void;
  setIsRecording: (isRecording: boolean) => void;
  setRecordingUrl: (url: string) => void;
  setTool: (url: string) => void;
  setColor: (color: Number3) => void;
}

interface PainterState {
  workerRef: Worker | null;

  color: Number3;
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
  const setColor = (color: Number3): void => set({ color });

  return {
    isRecording: false,
    recordingUrl: null,
    workerRef: null,

    color: [0.5, 0.5, 0.5],
    tool: "triangle",

    cb: {
      initWorker,
      setIsRecording,
      setRecordingUrl,
      setTool,
      setColor,
    },
  };
});

const selectStable = ({ cb, workerRef }: PainterState) => ({ cb, workerRef });
const useStable = (): Pick<PainterState, "cb" | "workerRef"> => {
  return useStore(selectStable, shallow);
};

interface FloatInputProps {
  prefix: string;
  data: number;
  setData: (data: number) => void;
}

const FloatInput: React.VFC<FloatInputProps> = ({ prefix, data, setData }) => {
  const [text, setText] = React.useState(() => `${data}`);
  const [error, setError] = React.useState(false);
  const paletteRef = React.useRef<HTMLDivElement>(null);

  React.useEffect(() => {
    const val = Number.parseFloat(text);

    const valIsInvalid = isNaN(val);
    setError(valIsInvalid);

    if (valIsInvalid) return;

    setData(val);
  }, [text, setError, setData]);

  return (
    <div className={styles.floatInWrapper}>
      {`${prefix}: `}
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

    const colorStyle = `rgb(${r * 256}, ${g * 256}, ${b * 256})`;
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
            <FloatInput
              prefix={"R"}
              data={r}
              setData={(r) => cb.setColor([r, g, b])}
            />

            <FloatInput
              prefix={"G"}
              data={g}
              setData={(g) => cb.setColor([r, g, b])}
            />

            <FloatInput
              prefix={"B"}
              data={b}
              setData={(b) => cb.setColor([r, g, b])}
            />
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

type CanvasRef = React.RefObject<HTMLCanvasElement>;
const Canvas: React.VFC<{ canvasRef: CanvasRef }> = ({ canvasRef }) => {
  const { cb, workerRef } = useStable();
  const isRecording = useStore((state) => state.isRecording);

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
    <canvas
      ref={canvasRef}
      className={styles.canvas}
      onMouseMove={(evt: React.MouseEvent<HTMLCanvasElement>) => {
        const data = [evt.clientX, evt.clientY];
        workerRef?.postMessage({ kind: "mousemove", data });
      }}
      onClick={(evt: React.MouseEvent<HTMLCanvasElement>) => {
        const data = [evt.clientX, evt.clientY];
        workerRef?.postMessage({ kind: "leftclick", data });
      }}
      onDoubleClick={(evt) => {
        evt.stopPropagation();
        evt.preventDefault();
      }}
      onContextMenu={(evt) => {
        evt.preventDefault();
        workerRef?.postMessage({ kind: "rightclick" });
      }}
    />
  );
};

const Painter: React.VFC = () => {
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
          cb.setColor(message.data);
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

  return (
    <div className={styles.wrapper}>
      <Canvas canvasRef={canvasRef} />
      <Config />
    </div>
  );
};

export default Painter;
