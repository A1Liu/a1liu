export const encoder = new TextEncoder();
export const decoder = new TextDecoder();

export const LOG = "log";

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

  postMessage: (kind: string, data: any) => void;
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

      const str = decoder.decode(buffer);

      const length = objectBuffer.length;
      objectBuffer.push(str);

      return length;
    },
    pushCopy: (idx: number) => {
      objectBuffer.push(objectBuffer[idx]);
    },

    // TODO some kind of pop stack operation that makes full objects or arrays
    // or whatever

    clearObjBufferForObjAndAfter: (idx: number) => {
      objectBuffer.length = idx;
    },
    clearObjBuffer: () => {
      objectBuffer.length = 0;
    },

    logObj: (idx: number) => ref.postMessage(LOG, objectBuffer[idx]),

    exitExt: (idx: number) => {
      const value = objectBuffer[idx];

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
