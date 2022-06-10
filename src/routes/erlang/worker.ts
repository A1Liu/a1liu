import * as wasm from "@lib/ts/wasm";
import { WorkerCtx } from "@lib/ts/util";

export type Number2 = [number, number];
export type Number3 = [number, number, number];
export type Number4 = [number, number, number, number];

export type Message =
  | { kind: "resize"; data: Number2 }
  | { kind: "scroll"; data: Number2 }
  | { kind: "mousemove"; data: Number2 }
  | { kind: "leftclick"; data: Number2 }
  | { kind: "rightclick"; data: Number2 }
  | { kind: "keydown"; data: number }
  | { kind: "keyup"; data: number }
  | { kind: "canvas"; offscreen: any };

const ctx = new WorkerCtx<Message>();
onmessage = ctx.onmessageCallback();

export type OutMessage =
  | { kind: "initDone"; data?: void }
  | { kind: string; data: any };

interface ErlangGl {
  ctx: WebGl;
}

const gglRef: { current: ErlangGl | null } = { current: null };

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

    // ctx.viewport(0, 0, ctx.canvas.width, ctx.canvas.height);
    wasmRef.abi.setDims(width, height);
  }
};

const initGl = async (canvas: any): Promise<ErlangGl | null> => {
  const ctx = canvas.getContext("2d");
  if (!ctx) return null;

  return { ctx };
};

const handleMessage = (wasmRef: wasm.Ref, msg: Message) => {
  switch (msg.kind) {
    case "scroll": {
      const [x, y] = msg.data;
      wasmRef.abi.onScroll(x, y);
      break;
    }

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
  const ctx2d = gglRef.current.ctx;
  const canvas = ctx2d.canvas;

  function run(timestamp: number) {
    ctx2d.clearRect(0, 0, canvas.width, canvas.height);

    wasmRef.abi.run(timestamp);

    requestAnimationFrame(run);
  }

  function run1(timestamp: number) {
    wasmRef.abi.setInitialTime(timestamp);
    requestAnimationFrame(run);
  }

  requestAnimationFrame(run1);

  while (true) {
    const captured = await ctx.msgWait();

    captured.forEach((msg) => handleMessage(wasmRef, msg));
  }
};

const init = async () => {
  const wasmRef = await wasm.fetchWasm("/erlang/erlang.wasm", {
    postMessage: (kind: string, data: any) => postMessage({ kind, data }),
    raw: (wasmRef: wasm.Ref) => ({
      setFont: (fontId: number) => {
        const font = wasmRef.readObj(fontId);
        gglRef.current.ctx.font = font;
      },

      fillText: (textId: number, x: number, y: number) => {
        const text = wasmRef.readObj(textId);
        gglRef.current.ctx.fillText(text, x, y);
      },

      strokeStyle: (rF: number, gF: number, bF: number, a: number) => {
        gglRef.current.ctx.globalAlpha = a;
        const [r, g, b] = [rF, gF, bF].map((f) => Math.floor(255 * f));

        gglRef.current.ctx.strokeStyle = `rgba(${r},${g},${b})`;
      },
      fillStyle: (rF: number, gF: number, bF: number, a: number) => {
        gglRef.current.ctx.globalAlpha = a;
        const [r, g, b] = [rF, gF, bF].map((f) => Math.floor(255 * f));

        gglRef.current.ctx.fillStyle = `rgba(${r},${g},${b})`;
      },

      strokeRect: (x: number, y: number, width: number, height: number) => {
        gglRef.current.ctx.strokeRect(x, y, width, height);
      },
      fillRect: (x: number, y: number, width: number, height: number) => {
        gglRef.current.ctx.fillRect(x, y, width, height);
      },
    }),
    imports: {},
  });

  while (true) {
    const captured = await ctx.msgWait();
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

  wasmRef.abi.init();

  main(wasmRef);
};

init();
