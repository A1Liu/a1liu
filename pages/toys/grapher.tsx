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
  initGl: (gl: WebGl, program: WebGLProgram) => void;
}

interface GrapherState {
  gl: WebGl | null;
  program: WebGLProgram | null;
  wasmRef: wasm.Ref | null;
  callbacks: GrapherCb;
}

const useStore = create<GrapherState>((set, get) => {
  const initWasm = (wasmRef: wasm.Ref) => set({ wasmRef });
  const initGl = (gl: WebGl, program: WebGLProgram) => set({ gl, program });

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

const Grapher: React.VFC = () => {
  const cb = useStore((state) => state.callbacks);
  const wasmRef = useStore((state) => state.wasmRef);
  const [text, setText] = React.useState("");
  const canvasRef = React.useRef<HTMLCanvasElement>(null);
  const toast = useToast();

  React.useEffect(() => {
    const gl = canvasRef.current?.getContext("webgl2");
    if (!gl) {
      toast.add("error", null, "WebGL2 not supported!");
      return;
    }

    const init = async () => {
      const [vertSrc, fragSrc] = await Promise.all([
        fetch("/assets/grapher.vert").then((r) => r.text()),
        fetch("/assets/grapher.frag").then((r) => r.text()),
      ]);

      const vertexShader = createShader(gl, gl.VERTEX_SHADER, vertSrc);
      const fragmentShader = createShader(gl, gl.FRAGMENT_SHADER, fragSrc);
      if (!vertexShader || !fragmentShader) return;

      const program = createProgram(gl, vertexShader, fragmentShader);
      if (!program) return;

      const posLocation = gl.getAttribLocation(program, "pos");
      const positionBuffer = gl.createBuffer();
      gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);

      // three 2d points
      const positions = [0, 0, 0, 0.5, 0.7, 0];
      gl.bufferData(
        gl.ARRAY_BUFFER,
        new Float32Array(positions),
        gl.STATIC_DRAW
      );

      const vao = gl.createVertexArray();
      gl.bindVertexArray(vao);

      gl.enableVertexAttribArray(posLocation);

      {
        const size = 2; // 2 components per iteration
        const type = gl.FLOAT; // the data is 32bit floats
        const normalize = false; // don't normalize the data
        const stride = 0; // 0 = move forward size * sizeof(type)
        const offset = 0; // start at the beginning of the buffer
        gl.vertexAttribPointer(
          posLocation,
          size,
          type,
          normalize,
          stride,
          offset
        );
      }

      resizeCanvasToDisplaySize(gl.canvas);

      gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);

      gl.clearColor(0, 0, 0, 0);
      gl.clear(gl.COLOR_BUFFER_BIT);

      gl.useProgram(program);

      // Bind the attribute/buffer set we want.
      gl.bindVertexArray(vao);

      {
        const primitiveType = gl.TRIANGLES;
        const offset = 0;
        const count = 3;
        gl.drawArrays(primitiveType, offset, count);
      }

      cb.initGl(gl, program);
      toast.add("success", null, "WebGL2 context initialized!");
    };

    init();
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

function createShader(
  gl: WebGl,
  shaderType: number,
  source: string
): WebGLShader | null {
  const shader = gl.createShader(shaderType);
  if (!shader) return null;

  gl.shaderSource(shader, source);
  gl.compileShader(shader);
  const success = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
  if (success) {
    return shader;
  }

  console.log(gl.getShaderInfoLog(shader));
  gl.deleteShader(shader);
  return null;
}

function createProgram(
  gl: WebGl,
  vertexShader: WebGLShader,
  fragmentShader: WebGLShader
): WebGLProgram | null {
  const program = gl.createProgram();
  if (!program) return null;

  gl.attachShader(program, vertexShader);
  gl.attachShader(program, fragmentShader);
  gl.linkProgram(program);
  const success = gl.getProgramParameter(program, gl.LINK_STATUS);
  if (success) {
    return program;
  }

  console.log(gl.getProgramInfoLog(program));
  gl.deleteProgram(program);
  return null;
}

function resizeCanvasToDisplaySize(canvas: HTMLCanvasElement): boolean {
  // Lookup the size the browser is displaying the canvas in CSS pixels.
  const displayWidth = canvas.clientWidth;
  const displayHeight = canvas.clientHeight;

  // Check if the canvas is not the same size.
  const needResize =
    canvas.width !== displayWidth || canvas.height !== displayHeight;

  if (needResize) {
    // Make the canvas the same size
    canvas.width = displayWidth;
    canvas.height = displayHeight;
  }

  return needResize;
}
