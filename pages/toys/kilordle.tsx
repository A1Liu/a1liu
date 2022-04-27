import React from "react";

// https://github.com/vercel/next.js/tree/canary/examples/with-web-worker

let wasmInstance: any = null;
let wasmExports: any = null;

const encoder = new TextEncoder();
const decoder = new TextDecoder();

const sendString = (str: string) => {
  const encodedString = encoder.encode(str);

  const u8 = new Uint8Array(exports.mem);

  // Copy the UTF-8 encoded string into the WASM memory.
  u8.set(encodedString);
};

const objectBuffer: any[] = [];

const imports = {
  env: {
    stringObjExt: (location: number, size: number): number => {
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

    clearObjBufferForObjAndAfter: (objIndex: number) => {
      objectBuffer.length = objIndex;
    },
    clearObjBuffer: () => {
      objectBuffer.length = 0;
    },

    logObj: (objIndex: number) => {
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

    exitExt: (objIndex: number) => {
      const value = objectBuffer[objIndex];

      throw new Error(`Crashed: ${value}`);
    },
  },
} as const;

export const Kilordle = () => {
  React.useEffect(() => {
    fetch("/kilordle.wasm")
      .then((resp) => WebAssembly.instantiateStreaming(resp, imports))
      .then((wasm) => {
        wasmInstance = wasm.instance;
        wasmExports = wasmInstance.exports;

        const result = wasmExports.add(1, 2);
        console.log(result);
      });
  }, []);

  return null;
};

export default Kilordle;
