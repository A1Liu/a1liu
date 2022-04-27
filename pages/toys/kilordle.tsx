import dynamic from "next/dynamic";

// https://github.com/vercel/next.js/tree/canary/examples/with-web-worker

let wasmInstance = null;
let wasmExports = null;

const encoder = new TextEncoder();
const decoder = new TextDecoder();

const sendString = (str) => {
  const encodedString = encoder.encode(str);

  const u8 = new Uint8Array(exports.mem);

  // Copy the UTF-8 encoded string into the WASM memory.
  u8.set(encodedString);
};

const objectBuffer = [];

const imports = {
  env: {
    stringObjExt: (location, size) => {
      const buffer = new Uint8Array(
        wasmInstance.exports.memory.buffer,
        location,
        size
      );

      const string = decoder.decode(buffer);

      const length = objectBuffer.length;
      objectBuffer.push(string);

      return length;
    },

    clearObjBufferForObjAndAfter: (objIndex) => {
      objectBuffer.length = objIndex;
    },
    clearObjBuffer: () => {
      objectBuffer.length = 0;
    },

    logObj: (objIndex) => {
      const value = objectBuffer[objIndex];

      if (typeof value === "string") {
        postMessage(value);
      } else {
        postMessage(JSON.stringify(value) + "\n");
      }
    },
    // clearTerminal: () => {
    //   terminalText.innerText = "";
    // },

    exitExt: (objIndex) => {
      const value = objectBuffer[objIndex];

      throw new Error(`Crashed: ${value}`);
    },
  },
};

fetch("/kilordle.wasm")
  .then((resp) => WebAssembly.instantiateStreaming(resp, imports))
  .then((wasm) => {
    wasmInstance = wasm.instance;
    wasmExports = wasmInstance.exports;

    const result = wasmExports.add(1, 2);
    console.log(result);
  });

export const Kilordle = () => {
  return null;
};

export default Kilordle;
