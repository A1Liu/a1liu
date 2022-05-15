import React from "react";
import Link from "next/link";
import shallow from "zustand/shallow";
import type { Message } from "src/painter.worker";
import type { Dispatch, SetStateAction } from "react";
import * as GL from "components/webgl";
import type { WebGl } from "components/webgl";
import styles from "./painter.module.css";
import css from "components/util.module.css";
import * as wasm from "components/wasm";
import { useToast, postToast } from "components/errors";
import cx from "classnames";
import create from "zustand";

interface PainterCb {
  initWorker: (workerRef: Worker) => void;
  setIsRecording: (isRecording: boolean) => void;
  setRecordingUrl: (url: string) => void;
  setTool: (url: string) => void;
}

interface PainterState {
  workerRef: Worker | null;

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

  return {
    isRecording: false,
    recordingUrl: null,
    workerRef: null,
    tool: "none",

    cb: {
      initWorker,
      setIsRecording,
      setRecordingUrl,
      setTool,
    },
  };
});

const useStable = (): Pick<PainterState, "cb" | "workerRef"> => {
  return useStore(({ cb, workerRef }) => ({ cb, workerRef }), shallow);
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

  const [tool, setTool] = React.useState("");
  const paletteRef = React.useRef<HTMLDivElement>(null);

  const [r, setR] = React.useState(0.5);
  const [g, setG] = React.useState(0.5);
  const [b, setB] = React.useState(0.5);

  React.useEffect(() => {
    if (recordingUrl === null) return;

    return () => URL.revokeObjectURL(recordingUrl);
  }, [recordingUrl]);

  React.useEffect(() => {
    if (!paletteRef.current) return;

    const color = `rgb(${r * 256}, ${g * 256}, ${b * 256})`;
    paletteRef.current.style.backgroundColor = color;
  }, [paletteRef, r, g, b]);

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
            <FloatInput prefix={"R"} data={r} setData={setR} />
            <FloatInput prefix={"G"} data={g} setData={setG} />
            <FloatInput prefix={"B"} data={b} setData={setB} />
          </div>
        </div>

        <div className={styles.configRow}>
          <button
            className={css.muiButton}
            onClick={() => cb.setIsRecording(!isRecording)}
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
          <video controls autoPlay muted width="100%">
            <source src={recordingUrl} type="video/webm" />

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

const Canvas: React.VFC = () => {
  const { cb, workerRef } = useStable();
  const isRecording = useStore((state) => state.isRecording);

  const canvasRef = React.useRef<HTMLCanvasElement>(null);
  const toast = useToast();

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
  }, [cb, isRecording]);

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
        const x = evt.clientX;
        const y = evt.clientY;

        const target = evt.currentTarget;
        const width = target.clientWidth;
        const height = target.clientHeight;

        workerRef?.postMessage({
          kind: "mousemove",
          data: [x, y, width, height],
        });
      }}
      onClick={(evt: React.MouseEvent<HTMLCanvasElement>) => {
        const x = evt.clientX;
        const y = evt.clientY;

        const target = evt.currentTarget;
        const width = target.clientWidth;
        const height = target.clientHeight;

        workerRef?.postMessage({
          kind: "leftclick",
          data: [x, y, width, height],
        });
      }}
      onContextMenu={(evt) => {
        evt.preventDefault();

        workerRef?.postMessage({ kind: "rightclick" });
      }}
    />
  );
};

const Painter: React.VFC = () => {
  const { cb } = useStable();

  React.useEffect(() => {
    const worker = new Worker(
      new URL("src/painter.worker.ts", import.meta.url)
    );
    worker.onmessage = (ev: MessageEvent<Message>) => {
      console.log(ev.data);
    };

    cb.initWorker(worker);
  }, [cb]);

  return (
    <div className={styles.wrapper}>
      <Canvas />
      <Config />
    </div>
  );
};

export default Painter;
