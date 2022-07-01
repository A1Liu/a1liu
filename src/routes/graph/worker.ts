import * as wasm from "@lib/ts/wasm";
import wasmUrl from "@zig/info-graph.wasm?url";
import { WorkerCtx } from "@lib/ts/util";
import { handleInput, findCanvas, InputMessage } from "@lib/ts/gamescreen";

const ctx = new WorkerCtx<InputMessage>();
onmessage = ctx.onmessageCallback();

export type OutMessage =
  | { kind: "initDone"; data?: void }
  | { kind: string; data: any };

interface GlContext {}

let glCtx = null;

const initGl = async (canvas: any): Promise<GlContext | null> => {
  const ctx = canvas.getContext("2d");
  if (!ctx) return null;

  return ctx;
};

const main = async (wasmRef: wasm.Ref) => {
  while (true) {
    const captured = await ctx.msgWait();

    const seen = {};
    captured.forEach((msg) => {
      switch (msg.kind) {
        default:
          handleInput(wasmRef, glCtx, msg);
      }

      seen[msg.kind] = msg;
    });
  }
};

const init = async () => {
  const wasmRef = await wasm.fetchWasm(wasmUrl, {
    postMessage: (kind: string, data: any) => postMessage({ kind, data }),
    raw: (wasmRef: wasm.Ref) => ({}),
    imports: {},
  });

  wasmRef.abi.init();

  const result = await findCanvas(ctx);
  glCtx = await initGl(result.canvas);

  if (!glCtx) {
    postMessage({ kind: "error", data: "WebGL2 not supported!" });
    return;
  }

  postMessage({ kind: "log", data: "WebGL2 context initialized!" });
  postMessage({ kind: "initDone" });

  result.remainder.forEach((msg) => {
    handleInput(wasmRef, glCtx, msg);
  });

  main(wasmRef);
};

init();
