import React from "react";
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

interface GrapherCb {
  initWasm: (wasmRef: wasm.Ref) => void;
  initGl: (gl: GrapherGl) => void;
}

interface GrapherGl {
  ctx: WebGl;
  program: WebGLProgram;
  vao: WebGLVertexArrayObject;
}

interface GrapherState {
  gl: GrapherGl | null;
  wasmRef: wasm.Ref | null;
  callbacks: GrapherCb;
}

const useStore = create<GrapherState>((set, get) => {
  const initWasm = (wasmRef: wasm.Ref) => set({ wasmRef });
  const initGl = (gl: GrapherGl) => set({ gl });

  return {
    gl: null,
    program: null,
    wasmRef: null,

    callbacks: {
      initWasm,
      initGl,
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

  const posLocation = 0;

  ctx.bindAttribLocation(program, posLocation, "pos");

  const positionBuffer = ctx.createBuffer();
  ctx.bindBuffer(ctx.ARRAY_BUFFER, positionBuffer);

  // three 2d points
  const positions = [0, 0, 0, 0.5, 0.7, 0];
  ctx.bufferData(
    ctx.ARRAY_BUFFER,
    new Float32Array(positions),
    ctx.STATIC_DRAW
  );

  ctx.bindVertexArray(vao);

  ctx.enableVertexAttribArray(posLocation);

  {
    const size = 2; // 2 components per iteration
    const type = ctx.FLOAT; // the data is 32bit floats
    const normalize = false; // don't normalize the data
    const stride = 0; // 0 = move forward size * sizeof(type)
    const offset = 0; // start at the beginning of the buffer
    ctx.vertexAttribPointer(posLocation, size, type, normalize, stride, offset);
  }

  ctx.bindVertexArray(null);

  const ggl: GrapherGl = { ctx, program, vao };

  return ggl;
};

const render = (ggl: GrapherGl) => {
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
    const count = 3;
    ctx.drawArrays(primitiveType, offset, count);
  }
};

const Grapher: React.VFC = () => {
  const cb = useStore((state) => state.callbacks);
  const wasmRef = useStore((state) => state.wasmRef);
  const [text, setText] = React.useState("");
  const canvasRef = React.useRef<HTMLCanvasElement>(null);
  const toast = useToast();

  React.useEffect(() => {
    initGl(canvasRef.current, cb).then((ggl) => {
      if (!ggl) {
        toast.add("error", null, "WebGL2 not supported!");
        return;
      }

      render(ggl);
      cb.initGl(ggl);

      toast.add("success", null, "WebGL2 context initialized!");
    });
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
