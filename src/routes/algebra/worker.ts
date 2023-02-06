import { initWasm } from "@lib/ts/wasm";
import type { WasmRef } from "@lib/ts/wasm";
import wasmUrl from "@zig/algebra.wasm?url";
import { WorkerCtx } from "@lib/ts/util";
import type { InputMessage as BaseMessage } from "@lib/ts/gamescreen";

export type InputMessage =
  | BaseMessage
  | { kind: "equationChange"; data: any }
  | { kind: "variableUpdate"; data: any };

export type OutMessage =
  | { kind: "initDone"; data?: void }
  | { kind: string; data: any };

const ctx = new WorkerCtx<InputMessage, OutMessage>(postMessage);
onmessage = ctx.onmessageCallback();

const main = async (wasmRef: WasmRef) => {
  while (true) {
    const captured = await ctx.msgWait();

    const seen: Record<string, any> = {};
    captured.forEach((msg) => {
      switch (msg.kind) {
        case "equationChange": {
          const obj = wasmRef.addObj(msg.data);
          wasmRef.abi.equationChange(obj);
          break;
        }

        case "variableUpdate": {
          const obj = wasmRef.addObj(msg.data.name);
          wasmRef.abi.variableUpdate(obj, msg.data.value);
          break;
        }

        default:
          ctx.postMessage(msg);
      }

      seen[msg.kind] = msg;
    });
  }
};

const graphStore = "graph-data";

const init = async () => {
  const wasmPromise = initWasm(fetch(wasmUrl), {
    postMessage: (kind: string, data: any) => ctx.postMessage({ kind, data }),
    raw: (wasmRef: WasmRef) => ({
      // timeout: () => wasmRef.addObj(timeout(2000)),
      // fetch: (...a: number[]) => {
      //   const res = fetch(...a.map(wasmRef.readObj)).then((res) => res.blob());
      //   const id = wasmRef.addObj(res, false);
      //   return id;
      // },
    }),
  });

  const wasmRef = await wasmPromise;

  wasmRef.abi.init();

  ctx.postMessage({ kind: "initDone" });

  main(wasmRef);
};

init();
