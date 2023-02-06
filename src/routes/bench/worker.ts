import { WorkerCtx } from "@lib/ts/util";
import type { WasmRef } from "@lib/ts/wasm";
import { initWasm } from "@lib/ts/wasm";
import wasmUrl from "@zig/bench.wasm?url";
import type { Message } from "./+page.svelte";

export type OutMessage = { kind: string; data: any };

const ctx = new WorkerCtx<Message>();
onmessage = ctx.onmessageCallback();

const handleMessage = (wasmRef: WasmRef, msg: Message) => {
  switch (msg.kind) {
    case "doBench": {
      postMessage({ kind: "benchStarted", data: performance.now() });

      const count = msg.data;
      for (let i = 0; i < count; i++) {
        wasmRef.abi.run();

        if (i % 32 === 0) {
          postMessage({ kind: "" });
        }
      }

      postMessage({ kind: "benchDone", data: performance.now() });
      break;
    }

    default:
      break;
  }
};

const main = async () => {
  const wasmRef = await initWasm(fetch(wasmUrl), {
    postMessage: (kind: string, data: any) => postMessage({ kind, data }),
    raw: (wasmRef: WasmRef) => ({}),
  });

  wasmRef.abi.init();

  postMessage({ kind: "initDone" });

  while (true) {
    const captured = await ctx.msgWait();

    captured.forEach((msg) => handleMessage(wasmRef, msg));
  }
};

main();
