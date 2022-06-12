import * as wasm from "@lib/ts/wasm";
import wasmUrl from "@zig/erlang.wasm?url";
import { WorkerCtx } from "@lib/ts/util";
import { handleInput, InputMessage } from "@lib/ts/gamescreen";

const ctx = new WorkerCtx<InputMessage>();
onmessage = ctx.onmessageCallback();

export type OutMessage =
  | { kind: "initDone"; data?: void }
  | { kind: string; data: any };

interface ErlangGl {
  ctx: WebGl;
}

const gglRef: { current: ErlangGl | null } = { current: null };

const initGl = async (canvas: any): Promise<ErlangGl | null> => {
  const ctx = canvas.getContext("2d");
  if (!ctx) return null;

  return { ctx };
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

    captured.forEach((msg) => handleInput(wasmRef, gglRef.current.ctx, msg));
  }
};

const init = async () => {
  const wasmRef = await wasm.fetchWasm(wasmUrl, {
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

  wasmRef.abi.init();

  let unhandled: any[] = [];
  while (true) {
    const captured = await ctx.msgWait();
    let offscreen = null;

    captured.forEach((msg) => {
      switch (msg.kind) {
        case "canvas":
          offscreen = msg.data;
          break;

        default:
          unhandled.push(msg);
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

  unhandled.forEach((msg) => {
    handleInput(wasmRef, gglRef.current.ctx, msg);
  });

  main(wasmRef);
};

init();
