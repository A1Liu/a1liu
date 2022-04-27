export const encoder = new TextEncoder();
export const decoder = new TextDecoder();

// WasmAbi should be
// allocate string
// allocate bytes
//
// later
// allocate array of integers
// allocate array of floats

export interface WasmRef {
  instance: any;
  abiExports: any;

  postMessage: (data: string) => void;
}

const sendString = (str: string) => {
  const encodedString = encoder.encode(str);

  const u8 = new Uint8Array(exports.mem);

  // Copy the UTF-8 encoded string into the WASM memory.
  u8.set(encodedString);
};

const env = (ref: WasmRef) => {
  const objectBuffer: any[] = [];

  return {
    stringObjExt: (location: number, size: number): number => {
      const buffer = new Uint8Array(
        ref.abiExports.memory.buffer,
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

      ref.postMessage(value);
    },
    // clearTerminal: () => {
    //   terminalText.innerText = "";
    // },

    exitExt: (objIndex: number) => {
      const value = objectBuffer[objIndex];

      throw new Error(`Crashed: ${value}`);
    },
  };
};

export const fetchWasm = async (
  path: string,
  ref: WasmRef
): Promise<WasmRef> => {
  const responsePromise = fetch(path);
  const imports = {
    env: env(ref),
  };

  const result = await WebAssembly.instantiateStreaming(
    responsePromise,
    imports
  );
  ref.instance = result.instance;
  ref.abiExports = result.instance.exports;

  return ref;
};
