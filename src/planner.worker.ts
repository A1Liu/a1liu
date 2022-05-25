import * as wasm from "components/wasm";

// TODO actually set up the message type
export type Message =
  | { kind: "keydown"; data: number }
  | { kind: "canvas"; offscreen: any };

let resolve: null | ((msg: Message[]) => void) = null;
const messages: Message[] = [];
onmessage = (event: MessageEvent<Message>) => {
  messages.push(event.data);
  if (resolve) {
    resolve(messages.splice(0, messages.length));
    resolve = null;
  }
};

const waitForMessage = (): Promise<Message[]> => {
  const p: Promise<Message[]> = new Promise((r) => (resolve = r));

  return p;
};

export type OutMessage =
  | { kind: "initDone"; data?: void }
  | { kind: string; data: any };

const handleMessage = (wasmRef: wasm.Ref, msg: Message) => {
  switch (msg.kind) {
    default:
      return;
  }
};

const main = async (wasmRef: wasm.Ref) => {
  while (true) {
    const captured = await waitForMessage();

    captured.forEach((msg) => handleMessage(wasmRef, msg));
  }
};

const init = async () => {
  const wasmRef = await wasm.fetchWasm("/planner/planner.wasm", {
    postMessage: (kind: string, data: any) => postMessage({ kind, data }),
    raw: (wasmRef: wasm.Ref) => ({}),
    imports: {},
  });

  wasmRef.abi.init();

  postMessage({ kind: "success", data: "WebGL2 context initialized!" });
  postMessage({ kind: "initDone" });

  main(wasmRef);
};

init();
