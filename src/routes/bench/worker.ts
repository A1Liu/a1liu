import { WorkerCtx } from "@lib/ts/util";
import * as wasm from "@lib/ts/wasm";
import wasmUrl from "@zig/bench.wasm?url";

const ctx = new WorkerCtx<Message>();
onmessage = ctx.onmessageCallback();

const handleMessage = (wasmRef: wasm.Ref, msg: Message) => {};

const main = async (wasmRef: wasm.Ref) => {
  while (true) {
    const captured = await ctx.msgWait();

    captured.forEach((msg) => handleMessage(wasmRef, msg));
  }
};

const init = async () => {
  const wasmRef = await wasm.fetchWasm(wasmUrl, {
    postMessage: (kind: string, data: any) => postMessage({ kind, data }),
    raw: (wasmRef: wasm.Ref) => ({}),
  });

  wasmRef.abi.init();

  postMessage({ kind: "initDone" });

  main(wasmRef);
};

init();
