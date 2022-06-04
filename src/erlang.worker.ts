import * as GL from "@lib/ts/webgl";
import * as wasm from "@lib/ts/wasm";

export type Number2 = [number, number];
export type Number3 = [number, number, number];
export type Number4 = [number, number, number, number];

export type Message =
  | { kind: "resize"; data: Number2 }
  | { kind: "mousemove"; data: Number2 }
  | { kind: "leftclick"; data: Number2 }
  | { kind: "rightclick"; data: Number2 }
  | { kind: "keydown"; data: number }
  | { kind: "keyup"; data: number }
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
  const p: Promise<Message[]> = new Promise((r) => {
    if (messages.length > 0) {
      return r(messages.splice(0, messages.length));
    }

    resolve = r;
  });

  return p;
};

export type OutMessage =
  | { kind: "initDone"; data?: void }
  | { kind: string; data: any };

interface ErlangGlState {
  renderId: number;
  rawTrianglesLength: number;
  colorsLength: number;
}

interface ErlangGl {
  ctx: WebGl;
  program: WebGLProgram;
  vao: WebGLVertexArrayObject;
  rawTriangles: WebGLBuffer;
  colors: WebGLBuffer;
}

const gglRef: { current: ErlangGl | null } = { current: null };
const glState: ErlangGlState = {
  rawTrianglesLength: 0,
  colorsLength: 0,
  renderId: 1,
};

const initGl = async (canvas: any): Promise<ErlangGl | null> => {
  const ctx: WebGl = canvas?.getContext("webgl2", {
    preserveDrawingBuffer: true,
  });

  if (!ctx) return null;

  const [vertSrc, fragSrc] = await Promise.all([
    fetch("/apps/painter.vert").then((r) => r.text()),
    fetch("/apps/painter.frag").then((r) => r.text()),
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

    case "rightclick": {
      const [x, y] = msg.data;
      wasmRef.abi.onRightClick(x, y);
      break;
    }

    case "keydown":
    case "keyup": {
      const down = msg.kind === "keydown";
      wasmRef.abi.onKey(down, msg.data);

      const data = `${msg.kind}: ${msg.data}`;
      // postMessage({ kind: "info", data });
      break;
    }

    case "resize": {
      const [width, height] = msg.data;
      resize(wasmRef, width, height);

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
  const wasmRef = await wasm.fetchWasm("/apps/erlang.wasm", {
    postMessage: (kind: string, data: any) => postMessage({ kind, data }),
    raw: (wasmRef: wasm.Ref) => ({}),
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

    wasmRef.abi.initialRender();
    break;
  }

  main(wasmRef);
};

init();
