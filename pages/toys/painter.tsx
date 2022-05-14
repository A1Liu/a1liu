import React from "react";
import Link from "next/link";
import shallow from "zustand/shallow";
import type { Dispatch, SetStateAction } from "react";
import * as GL from "components/webgl";
import type { WebGl } from "components/webgl";
import styles from "./painter.module.css";
import css from "components/util.module.css";
import * as wasm from "components/wasm";
import { useToast } from "components/errors";
import cx from "classnames";
import create from "zustand";

interface PainterCb {
  initWasm: (wasmRef: wasm.Ref) => void;
  initGl: (gl: PainterGl) => void;
  setRawTriangles: (floats: Float32Array) => void;
  setColors: (floats: Float32Array) => void;
  setIsRecording: (isRecording: boolean) => void;
  setRecordingUrl: (url: string) => void;
}

interface PainterGl {
  ctx: WebGl;
  program: WebGLProgram;
  vao: WebGLVertexArrayObject;
  rawTriangles: WebGLBuffer;
  colors: WebGLBuffer;
}

interface PainterGlState {
  renderId: number;
  rawTrianglesLength: number;
  colorsLength: number;
}

interface PainterState {
  gl: PainterGl | null;
  glState: PainterGlState;
  wasmRef: wasm.Ref | null;

  isRecording: boolean;
  recordingUrl: string | null;

  callbacks: PainterCb;
}

const useStore = create<PainterState>((set, get) => {
  const initWasm = (wasmRef: wasm.Ref) => set({ wasmRef });
  const initGl = (gl: PainterGl) => set({ gl });

  const setColors = (floats: Float32Array): void => {
    const { gl, glState } = get();
    if (!gl) return;

    const ctx = gl.ctx;

    ctx.bindBuffer(ctx.ARRAY_BUFFER, gl.colors);
    ctx.bufferData(ctx.ARRAY_BUFFER, floats, ctx.DYNAMIC_DRAW);

    set({
      glState: {
        ...glState,
        colorsLength: Math.floor(floats.length / 3),
        renderId: glState.renderId + 1,
      },
    });
  };

  const setRawTriangles = (floats: Float32Array): void => {
    const { gl, glState } = get();
    if (!gl) return;

    const ctx = gl.ctx;

    ctx.bindBuffer(ctx.ARRAY_BUFFER, gl.rawTriangles);
    ctx.bufferData(ctx.ARRAY_BUFFER, floats, ctx.DYNAMIC_DRAW);

    set({
      glState: {
        ...glState,
        rawTrianglesLength: Math.floor(floats.length / 2),
        renderId: glState.renderId + 1,
      },
    });
  };

  const setIsRecording = (isRecording: boolean): void => set({ isRecording });
  const setRecordingUrl = (recordingUrl: string): void => set({ recordingUrl });

  return {
    gl: null,
    glState: {
      renderId: 0,
      colorsLength: 0,
      rawTrianglesLength: 0,
    },

    isRecording: false,
    recordingUrl: null,

    wasmRef: null,

    callbacks: {
      initWasm,
      initGl,
      setRawTriangles,
      setColors,
      setIsRecording,
      setRecordingUrl,
    },
  };
});

const initGl = async (
  canvas: HTMLCanvasElement | null,
  cb: PainterCb
): Promise<PainterGl | null> => {
  const ctx = canvas?.getContext("webgl2");
  if (!ctx) {
    return null;
  }

  const [vertSrc, fragSrc] = await Promise.all([
    fetch("/assets/painter.vert").then((r) => r.text()),
    fetch("/assets/painter.frag").then((r) => r.text()),
  ]);

  const vertexShader = GL.createShader(ctx, ctx.VERTEX_SHADER, vertSrc);
  const fragmentShader = GL.createShader(ctx, ctx.FRAGMENT_SHADER, fragSrc);
  if (!vertexShader || !fragmentShader) return null;

  const program = GL.createProgram(ctx, vertexShader, fragmentShader);
  if (!program) return null;

  const vao = ctx.createVertexArray();
  if (!vao) return null;

  const rawTriangles = ctx.createBuffer();
  if (!rawTriangles) return null;

  const colors = ctx.createBuffer();
  if (!colors) return null;

  const posLocation = 0;
  const colorLocation = 1;

  ctx.bindAttribLocation(program, posLocation, "pos");
  ctx.bindAttribLocation(program, colorLocation, "color");

  ctx.bindVertexArray(vao);

  ctx.enableVertexAttribArray(posLocation);
  {
    ctx.bindBuffer(ctx.ARRAY_BUFFER, rawTriangles);

    const size = 2; // 2 components per iteration
    const type = ctx.FLOAT; // the data is 32bit floats
    const normalize = false; // don't normalize the data
    const stride = 0; // 0 = move forward size * sizeof(type)
    const offset = 0; // start at the beginning of the buffer
    ctx.vertexAttribPointer(posLocation, size, type, normalize, stride, offset);
  }

  ctx.enableVertexAttribArray(colorLocation);
  {
    ctx.bindBuffer(ctx.ARRAY_BUFFER, colors);

    const size = 3; // 2 components per iteration
    const type = ctx.FLOAT; // the data is 32bit floats
    const normalize = false; // don't normalize the data
    const stride = 0; // 0 = move forward size * sizeof(type)
    const offset = 0; // start at the beginning of the buffer
    ctx.vertexAttribPointer(
      colorLocation,
      size,
      type,
      normalize,
      stride,
      offset
    );
  }

  ctx.bindVertexArray(null);

  return { ctx, program, vao, rawTriangles, colors };
};

const render = (ggl: PainterGl, glState: PainterGlState) => {
  // console.log("GL rendering", glState);

  const ctx = ggl.ctx;

  GL.resizeCanvasToDisplaySize(ctx.canvas);

  ctx.viewport(0, 0, ctx.canvas.width, ctx.canvas.height);

  ctx.clearColor(0, 0, 0, 0);
  ctx.clear(ctx.COLOR_BUFFER_BIT);

  ctx.useProgram(ggl.program);

  // Bind the attribute/buffer set we want.
  ctx.bindVertexArray(ggl.vao);

  {
    const primitiveType = ctx.TRIANGLES;
    const offset = 0;
    ctx.drawArrays(primitiveType, offset, glState.rawTrianglesLength);
  }
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

    if (isNaN(val)) {
      setError(true);
      return;
    }

    setError(false);
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
  const cb = useStore((state) => state.callbacks);
  const wasmRef = useStore((state) => state.wasmRef);
  const [tool, setTool] = React.useState("");
  const paletteRef = React.useRef<HTMLDivElement>(null);

  const isRecording = useStore((state) => state.isRecording);
  const recordingUrl = useStore((state) => state.recordingUrl);

  const [r, setR] = React.useState(0.5);
  const [g, setG] = React.useState(0.5);
  const [b, setB] = React.useState(0.5);

  React.useEffect(() => {
    if (!wasmRef) return;

    const obj = wasmRef.abi.currentTool();
    const tool = wasmRef.readObj(obj);
    setTool(tool);
  }, [wasmRef, setTool]);

  React.useEffect(() => {
    if (recordingUrl === null) return;

    return () => URL.revokeObjectURL(recordingUrl);
  }, [recordingUrl]);

  React.useEffect(() => {
    if (!wasmRef) return;

    wasmRef.abi.setColor(r, g, b);
  }, [wasmRef, r, g, b]);

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
          onClick={() => {
            if (!wasmRef) return;

            wasmRef.abi.toggleTool();
            const obj = wasmRef.abi.currentTool();
            const tool = wasmRef.readObj(obj);
            setTool(tool);
          }}
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
            {isRecording ? "Stop Recording" : "Start Recording"}
          </button>
        </div>

        {recordingUrl ? (
          <video controls autoPlay muted width="100%">
            <source src={recordingUrl} type="video/mp4" />

            {"Sorry, your browser doesn't support embedded videos."}
          </video>
        ) : (
          <div>No recording available</div>
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
  const cb = useStore((state) => state.callbacks);
  const wasmRef = useStore((state) => state.wasmRef);
  const canvasRef = React.useRef<HTMLCanvasElement>(null);
  const toast = useToast();

  const ggl = useStore((state) => state.gl);
  const glState = useStore((state) => state.glState);

  const isRecording = useStore((state) => state.isRecording);

  React.useEffect(() => {
    const canvas = canvasRef.current;

    if (!canvas) return;
    if (!isRecording) return;

    const stream = canvas.captureStream(24);
    const mediaRecorder = new MediaRecorder(stream);
    const recordedChunks: any[] = [];

    mediaRecorder.ondataavailable = (e) => {
      if (e.data.size > 0) {
        recordedChunks.push(e.data);
      }
    };

    mediaRecorder.onstop = (e) => {
      const blob = new Blob(recordedChunks, {
        type: "video/mp4",
      });
      const url = URL.createObjectURL(blob);
      cb.setRecordingUrl(url);
    };

    mediaRecorder.start();

    return () => {
      mediaRecorder.stop();
    };
  }, [cb, isRecording]);

  React.useEffect(() => {
    initGl(canvasRef.current, cb).then((ggl) => {
      if (!ggl) {
        toast.add("error", null, "WebGL2 not supported!");
        return;
      }

      cb.initGl(ggl);
      toast.add("success", null, "WebGL2 context initialized!");
    });
  }, [canvasRef, toast, cb]);

  React.useEffect(() => {
    if (!ggl) return;

    render(ggl, glState);
  }, [ggl, glState]);

  return (
    <canvas
      ref={canvasRef}
      className={styles.canvas}
      onMouseMove={(evt) => {
        if (!wasmRef) return;

        const x = evt.clientX;
        const y = evt.clientY;

        const target = evt.target as HTMLCanvasElement;
        const width = target.clientWidth;
        const height = target.clientHeight;

        wasmRef.abi.onMove(x, y, width, height);
      }}
      onClick={(evt) => {
        if (!wasmRef) return;

        const x = evt.clientX;
        const y = evt.clientY;

        const target = evt.target as HTMLCanvasElement;
        const width = target.clientWidth;
        const height = target.clientHeight;

        wasmRef.abi.onClick(x, y, width, height);
      }}
      onContextMenu={(evt) => {
        evt.preventDefault();

        if (!wasmRef) return;

        wasmRef.abi.onRightClick();
      }}
    />
  );
};

const Painter: React.VFC = () => {
  const cb = useStore((state) => state.callbacks);

  React.useEffect(() => {
    const wasmPromise = wasm.fetchWasm("/assets/painter.wasm", {
      postMessage: wasm.postToast,
      raw: {},
      imports: {
        setTriangles: cb.setRawTriangles,
        setColors: cb.setColors,
      },
    });

    wasmPromise.then((ref) => {
      ref.abi.init();
      cb.initWasm(ref);
    });
  }, [cb]);

  return (
    <div className={styles.wrapper}>
      <Canvas />
      <Config />
    </div>
  );
};

export default Painter;
