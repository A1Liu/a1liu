import * as wasm from "src/wasm";

// TODO actually set up the message type
export type Message =
  | { kind: "keydown"; data: number }
  | { kind: "canvas"; offscreen: any };

let resolve: null | ((msg: Message[]) => void) = null;
const messages: Message[] = [];
onmessage = (event: MessageEvent<Message>) => {
  messages.push(event.data);
  resolve?.(messages.splice(0, messages.length));
  resolve = null;
};

const waitForMessage = (): Promise<Message[]> => {
  const p: Promise<Message[]> = new Promise((r) => (resolve = r));

  return p;
};

interface EventDisplayData {
  // Day of week, sunday = 0, saturday = 6
  day: number;

  // Time of day in minutes, inclusive; min = 0, max = 1339
  beginTime: number;

  // Time of day in minutes, exclusive; min = 0, max = 1440
  endTime: number;
}

interface PClass {
  // Public-facing integer
  id: number;
}

export interface PObject {
  classId: number;

  begin: Date;
  end: Date;
}

const makeDate = (hours: number): Date => {
  const date = new Date();
  date.setHours(hours);
  date.setMinutes(0);
  date.setSeconds(0);

  return date;
};

const classes: Record<number, PClass> = {
  [1]: { id: 1 },
};

const output: PObject[] = [
  {
    classId: 1,
    begin: makeDate(10),
    end: makeDate(11),
  },
  {
    classId: 1,
    begin: makeDate(8),
    end: makeDate(9),
  },
];

export type OutMessage =
  | { kind: "initDone"; data?: void }
  | { kind: "sendData"; data: PObject[] }
  | { kind: "showEvents"; data: EventDisplayData[] }
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
  const wasmRef = await wasm.fetchWasm("/apps/planner/planner.wasm", {
    postMessage: (kind: string, data: any) => postMessage({ kind, data }),
    raw: (wasmRef: wasm.Ref) => ({}),
    imports: {},
  });

  wasmRef.abi.init();

  postMessage({ kind: "initDone" });
  postMessage({ kind: "sendData", data: output });

  main(wasmRef);
};

init();
