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

const graphStore = "graph-data";

const init = async () => {
  const request = indexedDB.open("info-graph");
  request.onupgradeneeded = () => {
    request.result.createObjectStore(graphStore, { autoIncrement: true });
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
      idbGet: (storeId: number, id: number) => {
        const storeName = wasmRef.readObj(storeId);
        const transaction = db.transaction(storeName, "readonly");
        const store = transaction.objectStore(graphStore);
        const promise = idb.promisifyRequest(store.get(id));

        return wasmRef.addObj(promise);
      },

      idbSet: (storeId: number, id: number, objId: number) => {
        const storeName = wasmRef.readObj(storeId);
        const transaction = db.transaction(storeName, "readwrite");
        const store = transaction.objectStore(graphStore);
        const promise = idb.promisifyRequest(transaction);

        // This prevents the entire ArrayBuffer from being structurally cloned
        const obj = wasmRef.readObj(objId);
        const storage = new ArrayBuffer(obj.length);
        const byteView = new Uint8Array(storage);
        byteView.set(obj);

        store.put(byteView, id);

        return wasmRef.addObj(promise);
      },
    }),
  });

  db = await dbPromise;
  const wasmRef = await wasmPromise;

  wasmRef.abi.init();

  postMessage({ kind: "initDone" });

  main(wasmRef);
};

init();
