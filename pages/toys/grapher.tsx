import React from "react";
import shallow from "zustand/shallow";
import type { Dispatch, SetStateAction } from "react";
import * as GL from "components/webgl";
import type { WebGl } from "components/webgl";
import css from "./grapher.module.css";
import * as wasm from "components/wasm";
import { useToast } from "components/errors";
import cx from "classnames";
import create from "zustand";

// User sets image size/resolution manually
// User customizes basically every part

// step 1: simple drawing stuffs

interface GrapherCb {
  initWasm: (wasmRef: wasm.Ref) => void;
  initGl: (gl: GrapherGl) => void;
  setRawTriangles: (floats: Float32Array) => void;
}

interface GrapherGl {
  ctx: WebGl;
  program: WebGLProgram;
  vao: WebGLVertexArrayObject;
  rawTriangles: WebGLBuffer;
}

interface GrapherGlState {
  renderId: number;
  rawTrianglesLength: number;
}

interface GrapherState {
  gl: GrapherGl | null;
  glState: GrapherGlState;
  wasmRef: wasm.Ref | null;

  callbacks: GrapherCb;
}

const useStore = create<GrapherState>((set, get) => {
  const initWasm = (wasmRef: wasm.Ref) => set({ wasmRef });
  const initGl = (gl: GrapherGl) => set({ gl });

  const setRawTriangles = (floats: Float32Array): void => {
    const { gl, glState } = get();
    if (!gl) return;

    const ctx = gl.ctx;

    ctx.bindBuffer(ctx.ARRAY_BUFFER, gl.rawTriangles);
    ctx.bufferData(ctx.ARRAY_BUFFER, floats, ctx.STATIC_DRAW);

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
      rawTrianglesLength: 0,
    },

    wasmRef: null,

    callbacks: {
      initWasm,
      initGl,
      setRawTriangles,
    },
  };
});

const initGl = async (
  canvas: HTMLCanvasElement | null,
  cb: GrapherCb
): Promise<GrapherGl | null> => {
  const ctx = canvas?.getContext("webgl2");
  if (!ctx) {
    return null;
  }

  const [vertSrc, fragSrc] = await Promise.all([
    fetch("/assets/grapher.vert").then((r) => r.text()),
    fetch("/assets/grapher.frag").then((r) => r.text()),
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

  const posLocation = 0;
  ctx.bindAttribLocation(program, posLocation, "pos");

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

  ctx.bindVertexArray(null);

  return { ctx, program, vao, rawTriangles };
};

const render = (ggl: GrapherGl, glState: GrapherGlState) => {
  console.log("GL rendering", glState);

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

  return (
    <form
      className={css.config}
      onSubmit={(evt: React.FormEvent<HTMLFormElement>) => {
        evt.preventDefault();

        if (!wasmRef) return;

        const target = evt.target as HTMLFormElement;
        const data: Record<string, HTMLInputElement> = {};
        Array.from(target.elements).forEach((e: any) => (data[e.name] = e));

        const idx = wasmRef.addObj(data.blarg.value);
        wasmRef.abi.print(idx);
      }}
    >
      <h3>Settings</h3>

      <label className={css.configRow}>
        Name: <input type="text" name="blarg" />
      </label>

      <input type="submit" value="Submit" />
    </form>
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
      className={css.canvas}
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
        if (!wasmRef) return;

        evt.preventDefault();
        wasmRef.abi.onRightClick();
      }}
    />
  );
};

const Grapher: React.VFC = () => {
  const cb = useStore((state) => state.callbacks);

  React.useEffect(() => {
    const wasmPromise = wasm.fetchWasm("/assets/grapher.wasm", {
      postMessage: wasm.postToast,
      imports: { setTriangles: cb.setRawTriangles },
      raw: {},
    });

    wasmPromise.then((ref) => {
      ref.abi.init();
      cb.initWasm(ref);
    });
  }, [cb]);

  return (
    <div className={css.wrapper}>
      <Canvas />
      <Config />
    </div>
  );
};

export default Grapher;
