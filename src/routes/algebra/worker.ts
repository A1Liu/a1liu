import { initWasm } from "@lib/ts/wasm";
import type { WasmRef } from "@lib/ts/wasm";
import wasmUrl from "@zig/algebra.wasm?url";
import { WorkerCtx, timeout } from "@lib/ts/util";
import type { InputMessage } from "@lib/ts/gamescreen";

const ctx = new WorkerCtx<InputMessage>();
onmessage = ctx.onmessageCallback();

export type OutMessage =
  | { kind: "initDone"; data?: void }
  | { kind: string; data: any };

const main = async (wasmRef: WasmRef) => {
  while (true) {
    const captured = await ctx.msgWait();

    const seen = {};
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
          postMessage(msg);
      }

      seen[msg.kind] = msg;
    });
  }
};

const graphStore = "graph-data";

const init = async () => {
  const wasmPromise = initWasm(fetch(wasmUrl), {
    postMessage: (kind: string, data: any) => postMessage({ kind, data }),
    raw: (wasmRef: wasm.Ref) => ({
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

  postMessage({ kind: "initDone" });

  main(wasmRef);
};

init();
