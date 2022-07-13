import { WorkerCtx } from "@lib/ts/util";
import * as wasm from "@lib/ts/wasm";
import wasmUrl from "@zig/bench.wasm?url";

const ctx = new WorkerCtx<Message>();
onmessage = ctx.onmessageCallback();

const handleMessage = (wasmRef: wasm.Ref, msg: Message) => {
  switch (msg.kind) {
    case "doBench": {
      postMessage({ kind: "benchStarted", data: performance.now() });

      const count = msg.data;
      for (let i = 0; i < count; i++) {
        wasmRef.abi.run();
      }

      postMessage({ kind: "benchDone", data: performance.now() });
      break;
    }

    default:
      break;
  }
};

const main = async () => {
  const wasmRef = await wasm.fetchWasm(wasmUrl, {
    postMessage: (kind: string, data: any) => postMessage({ kind, data }),
    raw: (wasmRef: wasm.Ref) => ({}),
  });

  wasmRef.abi.init();

  postMessage({ kind: "initDone" });

  while (true) {
    const captured = await ctx.msgWait();

    captured.forEach((msg) => handleMessage(wasmRef, msg));
  }
};

main();
