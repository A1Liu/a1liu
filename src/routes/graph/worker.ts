import * as wasm from "@lib/ts/wasm";
import wasmUrl from "@zig/info-graph.wasm?url";
import { WorkerCtx, timeout } from "@lib/ts/util";
import * as idb from "idb-keyval";

const ctx = new WorkerCtx<InputMessage>();
onmessage = ctx.onmessageCallback();

export type OutMessage =
  | { kind: "initDone"; data?: void }
  | { kind: string; data: any };

interface GlContext {}

let db = undefined;
let glCtx = null;

const initGl = async (canvas: any): Promise<GlContext | null> => {
  const ctx = canvas.getContext("2d");
  if (!ctx) return null;

  return ctx;
};

const main = async (wasmRef: wasm.Ref) => {
  // idb.set(0, new TextEncoder().encode("warg"));
  // idb.del(0);

  while (true) {
    const captured = await ctx.msgWait();

    const seen = {};
    captured.forEach((msg) => {
      switch (msg.kind) {
        default:
          postMessage(msg);
      }

      seen[msg.kind] = msg;
    });
  }
};

const init = async () => {
  const request = indexedDB.open("info-graph");
  request.onupgradeneeded = () => {
    request.result.createObjectStore("graph-data", { autoIncrement: true });
  };
  const dbPromise = idb.promisifyRequest(request);

  const wasmPromise = wasm.fetchWasm(wasmUrl, {
    postMessage: (kind: string, data: any) => postMessage({ kind, data }),
    raw: (wasmRef: wasm.Ref) => ({
      timeout: () => wasmRef.addObj(timeout(2000)),
      fetch: (...a: number[]) => {
        const res = fetch(...a.map(wasmRef.readObj)).then((res) => res.blob());
        const id = wasmRef.addObj(res, false);

        return id;
      },
      idbGet: (id: number) => {
        return wasmRef.addObj(idb.get(id));
      },
      idbSet: (id: number, objId: number) => {
        const obj = wasmRef.readObj(objId);
        return wasmRef.addObj(idb.set(id, obj));
      },
    }),
    imports: {},
  });

  db = await dbPromise;
  const wasmRef = await wasmPromise;

  wasmRef.abi.init();

  postMessage({ kind: "initDone" });

  main(wasmRef);
};

init();
