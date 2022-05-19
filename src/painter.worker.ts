import * as GL from "components/webgl";
import type { WebGl } from "components/webgl";
import * as wasm from "components/wasm";

export type Number2 = [number, number];
export type Number3 = [number, number, number];
export type Number4 = [number, number, number, number];

export type Message =
  | { kind: "toggleTool" }
  | { kind: "resize"; data: Number2 }
  | { kind: "setColor"; data: Number3 }
  | { kind: "mousemove"; data: Number2 }
  | { kind: "leftclick"; data: Number2 }
  | { kind: "rightclick" }
  | { kind: "canvas"; offscreen: any };

let resolve: null | ((msg: Message[]) => void) = null;
const messages: Message[] = [];
onmessage = (event: MessageEvent<Message>) => {
  messages.push(event.data);
  if (resolve) {
    resolve(messages.splice(0, messages.length));
    resolve = null;
  }
};

const waitForMessage = (): Promise<Message[]> => {
  const p: Promise<Message[]> = new Promise((r) => (resolve = r));

  return p;
};

export type OutMessage =
  | { kind: "initDone"; data?: void }
  | { kind: "setTool"; data: string }
  | { kind: "setColor"; data: Number3 }
  | { kind: string; data: any };

interface PainterGlState {
  renderId: number;
  rawTrianglesLength: number;
  colorsLength: number;
}

interface PainterGl {
  ctx: WebGl;
  program: WebGLProgram;
  vao: WebGLVertexArrayObject;
  rawTriangles: WebGLBuffer;
  colors: WebGLBuffer;
}

const gglRef: { current: PainterGl | null } = { current: null };
const glState: PainterGlState = {
  rawTrianglesLength: 0,
  colorsLength: 0,
  renderId: 1,
};

const initGl = async (canvas: any): Promise<PainterGl | null> => {
  const ctx: WebGl = canvas?.getContext("webgl2");
  if (!ctx) return null;

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

const resize = (wasmRef: wasm.Ref, width: number, height: number) => {
  const ggl = gglRef.current;
  if (!ggl) return;

  const ctx = ggl.ctx;

  // Check if the canvas is not the same size.
  const needResize = ctx.canvas.width !== width || ctx.canvas.height !== height;

  if (needResize) {
    // Make the canvas the same size
    ctx.canvas.width = width;
    ctx.canvas.height = height;

    ctx.viewport(0, 0, ctx.canvas.width, ctx.canvas.height);
    wasmRef.abi.setDims(width, height);

    glState.renderId = glState.renderId + 1;
  }
};

function render() {
  const ggl = gglRef.current;
  if (!ggl) return;

  const ctx = ggl.ctx;

  ctx.clearColor(1, 1, 1, 1);
  ctx.clear(ctx.COLOR_BUFFER_BIT);

  ctx.useProgram(ggl.program);

  // Bind the attribute/buffer set we want.
  ctx.bindVertexArray(ggl.vao);

  {
    const primitiveType = ctx.TRIANGLES;
    const offset = 0;
    ctx.drawArrays(primitiveType, offset, glState.rawTrianglesLength);
  }

  // Technically maybe we don't have to do this every frame if nothing updates.
  // However, the media recorder seems to skip frames when we don't forcibly
  // re-render at every opportunity. Oh well.
  //                                - Albert Liu, May 15, 2022 Sun 02:25 EDT
  requestAnimationFrame(render);
}

const updateState = (
  triangles: Float32Array | null,
  colors: Float32Array | null
) => {
  const ggl = gglRef.current;
  if (!ggl) return;

  const ctx = ggl.ctx;

  if (triangles !== null) {
    ctx.bindBuffer(ctx.ARRAY_BUFFER, ggl.rawTriangles);
    ctx.bufferData(ctx.ARRAY_BUFFER, triangles, ctx.DYNAMIC_DRAW);

    glState.rawTrianglesLength = Math.floor(triangles.length / 2);
    glState.renderId = glState.renderId + 1;
  }

  if (colors !== null) {
    ctx.bindBuffer(ctx.ARRAY_BUFFER, ggl.colors);
    ctx.bufferData(ctx.ARRAY_BUFFER, colors, ctx.DYNAMIC_DRAW);

    glState.colorsLength = Math.floor(colors.length / 3);
    glState.renderId = glState.renderId + 1;
  }
};

const handleMessage = (wasmRef: wasm.Ref, msg: Message) => {
  switch (msg.kind) {
    case "mousemove": {
      const [x, y] = msg.data;
      wasmRef.abi.onMove(x, y);
      break;
    }

    case "leftclick": {
      const [x, y] = msg.data;
      wasmRef.abi.onClick(x, y);
      break;
    }

    case "rightclick":
      wasmRef.abi.onRightClick();
      break;

    case "resize": {
      const [width, height] = msg.data;
      resize(wasmRef, width, height);
      break;
    }

    case "setColor": {
      const [r, g, b] = msg.data;
      wasmRef.abi.setColor(r, g, b);
      break;
    }

    case "toggleTool": {
      const obj = wasmRef.abi.toggleTool();
      const data = wasmRef.readObj(obj);
      postMessage({ kind: "setTool", data });
      break;
    }

    default:
      return;
  }
};

const main = async (wasmRef: wasm.Ref) => {
  requestAnimationFrame(render);

  while (true) {
    const captured = await waitForMessage();

    captured.forEach((msg) => handleMessage(wasmRef, msg));
  }
};

const init = async () => {
  const wasmRef = await wasm.fetchWasm("/assets/painter.wasm", {
    postMessage: (kind: string, data: any) => postMessage({ kind, data }),
    raw: {},
    imports: {
      renderExt: (tri: Float32Array | null, colors: Float32Array | null) =>
        updateState(tri, colors),
    },
  });

  wasmRef.abi.init();

  while (true) {
    const captured = await waitForMessage();
    let offscreen = null;

    captured.forEach((msg) => {
      switch (msg.kind) {
        case "canvas":
          offscreen = msg.offscreen;
          break;

        default:
          handleMessage(wasmRef, msg);
          break;
      }
    });

    if (offscreen === null) continue;

    const ggl = await initGl(offscreen);

    if (!ggl) {
      postMessage({ kind: "error", data: "WebGL2 not supported!" });
      return;
    }

    gglRef.current = ggl;

    postMessage({ kind: "success", data: "WebGL2 context initialized!" });
    postMessage({ kind: "initDone" });
    break;
  }

  main(wasmRef);
};

init();
