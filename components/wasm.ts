export const encoder = new TextEncoder();
export const decoder = new TextDecoder();

export const LOG = "log";

// WasmAbi should be
// allocate bytes
//
// later
// allocate array of integers
// allocate array of floats

export interface WasmRef {
  instance: any;
  abi: any;
  defer: any;
}

export function ref(): WasmRef {
  return {
    instance: null,
    abi: null,
    defer: null,
  };
}

interface Imports {
  postMessage: (kind: string, data: any) => void;

  // Keys can be strings, numbers, or symbols.
  // If you know it to be strings only, you can also restrict it to that.
  // For the value you can use any or unknown,
  // with unknown being the more defensive approach.
  [x: string | number | symbol]: unknown;
}

const sendString = (str: string) => {
  const encodedString = encoder.encode(str);

  const u8 = new Uint8Array(exports.mem);

  // Copy the UTF-8 encoded string into the WASM memory.
  u8.set(encodedString);
};

const env = (ref: WasmRef, imports: Imports) => {
  const { postMessage, ...extra } = imports;
  const objectBuffer: any[] = [];

  return {
    stringObjExt: (location: number, size: number): number => {
      const buffer = new Uint8Array(ref.abi.memory.buffer, location, size);

      const str = decoder.decode(buffer);

      const length = objectBuffer.length;
      objectBuffer.push(str);

      return length;
    },
    pushCopy: (idx: number): number => {
      const length = objectBuffer.length;
      objectBuffer.push(objectBuffer[idx]);
      return length;
    },

    // TODO some kind of pop stack operation that makes full objects or arrays
    // or whatever

    clearObjBufferForObjAndAfter: (idx: number) => {
      objectBuffer.length = idx;
    },
    clearObjBuffer: () => {
      objectBuffer.length = 0;
    },

    logObj: (idx: number) => postMessage(LOG, objectBuffer[idx]),

    exitExt: (idx: number) => {
      const value = objectBuffer[idx];

      throw new Error(`Crashed: ${value}`);
    },

    ...extra,
  };
};

export const fetchWasm = async (
  path: string,
  ref: WasmRef,
  imports: Imports
): Promise<WasmRef> => {
  const responsePromise = fetch(path);
  const importObject = {
    env: env(ref, imports),
  };

  const result = await WebAssembly.instantiateStreaming(
    responsePromise,
    importObject
  );
  ref.instance = result.instance;
  ref.abi = result.instance.exports;
  ref.defer = {};

  Object.entries(ref.abi).forEach(([key, value]: [string, any]) => {
    ref.defer[key] = (...t: any[]) => setTimeout(() => value(...t), 0);
  });

  return ref;
};
