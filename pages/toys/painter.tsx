import React from "react";
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

  return {
    gl: null,
    glState: {
      renderId: 0,
      colorsLength: 0,
      rawTrianglesLength: 0,
    },

    wasmRef: null,

    callbacks: {
      initWasm,
      initGl,
      setRawTriangles,
      setColors,
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

const Config: React.VFC = () => {
  const cb = useStore((state) => state.callbacks);
  const wasmRef = useStore((state) => state.wasmRef);
  const [tool, setTool] = React.useState("");

  const [r, setR] = React.useState(0.5);
  const [g, setG] = React.useState(0.5);
  const [b, setB] = React.useState(0.5);

  React.useEffect(() => {
    if (!wasmRef) return;

    const obj = wasmRef.abi.currentTool();
    const tool = wasmRef.readObj(obj);
    setTool(tool);
  }, [wasmRef, setTool]);

  return (
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

      <input
        value={`${r}`}
        onChange={(evt) => {
          if (!wasmRef) return;

          const val = Number.parseFloat(evt.target.value);
          if (isNaN(val)) return;

          setR(val);
          wasmRef.abi.setColor(val, g, b);
        }}
      />

      <input
        value={`${g}`}
        onChange={(evt) => {
          if (!wasmRef) return;

          const val = Number.parseFloat(evt.target.value);
          if (isNaN(val)) return;

          setG(val);
          wasmRef.abi.setColor(r, val, b);
        }}
      />

      <input
        value={`${b}`}
        onChange={(evt) => {
          if (!wasmRef) return;

          const val = Number.parseFloat(evt.target.value);
          if (isNaN(val)) return;

          setB(val);
          wasmRef.abi.setColor(r, g, val);
        }}
      />
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
        wasmRef.abi.onMove(x, y, target.width, target.height);
      }}
      onClick={(evt) => {
        if (!wasmRef) return;

        const x = evt.clientX;
        const y = evt.clientY;
        const target = evt.target as HTMLCanvasElement;
        wasmRef.abi.onClick(x, y, target.width, target.height);
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
