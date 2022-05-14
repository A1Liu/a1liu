import * as GL from "components/webgl";
import type { WebGl } from "components/webgl";
import * as wasm from "components/wasm";

export type Message = { kind: "canvas"; offscreen: any };

const messages: MessageEvent<Message>[] = [];
onmessage = (event: MessageEvent<Message>) => {
  messages.push(event);
};

postMessage("bello");
