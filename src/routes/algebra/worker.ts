import * as wasm from "@lib/ts/wasm";
import wasmUrl from "@zig/algebra.wasm?url";
import { WorkerCtx, timeout } from "@lib/ts/util";
import * as idb from "idb-keyval";

const ctx = new WorkerCtx<InputMessage>();
onmessage = ctx.onmessageCallback();

export type OutMessage =
  | { kind: "initDone"; data?: void }
  | { kind: string; data: any };

const main = async (wasmRef: wasm.Ref) => {
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

        default:
          postMessage(msg);
      }

      seen[msg.kind] = msg;
    });
  }
};

const graphStore = "graph-data";

const init = async () => {
  const wasmPromise = wasm.fetchWasm(wasmUrl, {
    postMessage: (kind: string, data: any) => postMessage({ kind, data }),
    raw: (wasmRef: wasm.Ref) => ({
      timeout: () => wasmRef.addObj(timeout(2000)),
      fetch: (...a: number[]) => {
        const res = fetch(...a.map(wasmRef.readObj)).then((res) => res.blob());
        const id = wasmRef.addObj(res, false);

        return id;
      },
    }),
  });

  const wasmRef = await wasmPromise;

  wasmRef.abi.init();

  postMessage({ kind: "initDone" });

  main(wasmRef);
};

init();
