import * as wasm from "components/wasm";

const messages = [];
onmessage = (event) => {
  messages.push(ev);
};

postMessage("hello");
