export const encoder = new TextEncoder();
export const decoder = new TextDecoder();

// WasmAbi should be
// allocate bytes
//
// later
// allocate array of integers
// allocate array of floats

// These could be more advanced but, meh
type WasmFunc = (...data: any[]) => any;
type AsyncWasmFunc = (...data: any[]) => Promise<any>;

export interface WasmRef {
  readonly instance: any;
  readonly memory: WebAssembly.Memory;
  readonly abi: { readonly [x: string]: WasmFunc };
  readonly defer: { readonly [x: string]: AsyncWasmFunc };
  readonly pushObj: (obj: any) => number;
}

export function ref(): WasmRef {
  return {
    instance: null,
    memory: null as any,
    abi: null as any,
    defer: {},
    pushObj: () => -1,
  };
}

interface Imports {
  readonly postMessage: (kind: string, data: any) => void;
  readonly raw?: { readonly [x: string]: WasmFunc };
  readonly imports: { readonly [x: string]: WasmFunc };
}

const sendString = (str: string) => {
  const encodedString = encoder.encode(str);

  const u8 = new Uint8Array(exports.mem);

  // Copy the UTF-8 encoded string into the WASM memory.
  u8.set(encodedString);
};

interface WasmRefInner {
  instance: any;
  abi: {
    [x: string]: WasmFunc;
  };
  defer: { [x: string]: AsyncWasmFunc };
  pushObj: (obj: any) => number;
}

const initialObjectBuffer: any[] = ["log", "info", "warn", "error", "success"];

export const fetchWasm = async (
  path: string,
  importData: Imports
): Promise<WasmRef> => {
  const responsePromise = fetch(path);

  const ref: WasmRef = {
    instance: {} as any,
    memory: {} as any,
    abi: {} as any,
    defer: {} as any,
    pushObj: (data) => {
      const idx = objectBuffer.length;
      objectBuffer.push(data);
      return idx;
    },
  };

  const { postMessage, raw } = importData;

  const imports = { postMessage, ...importData.imports };
  const objectBuffer = [...initialObjectBuffer];
  const initialLen = objectBuffer.length;

  const wasmImports = {} as any;
  Object.entries(imports).forEach(([key, value]: [string, any]) => {
    wasmImports[key] = (...args: number[]) =>
      value(...args.map((idx) => objectBuffer[idx]));
  });

  const env = {
    stringObjExt: (location: number, size: number): number => {
      const buffer = new Uint8Array(ref.memory.buffer, location, size);

      const str = decoder.decode(buffer);

      const length = objectBuffer.length;
      objectBuffer.push(str);

      return length;
    },

    // TODO some kind of pop stack operation that makes full objects or arrays
    // or whatever

    watermarkObj: (idx: number) => objectBuffer.length,
    clearObjBufferForObjAndAfter: (idx: number) => {
      objectBuffer.length = idx;
    },
    clearObjBuffer: () => {
      objectBuffer.length = initialLen;
    },

    makeArray: () => {
      const idx = objectBuffer.length;
      objectBuffer.push([]);

      return idx;
    },
    makeObj: () => {
      const idx = objectBuffer.length;
      objectBuffer.push({});

      return idx;
    },

    arrayPush: (arrayIdx: number, valueIdx: number) => {
      const arr = objectBuffer[arrayIdx];
      const value = objectBuffer[valueIdx];

      arr.push(value);
    },
    objSet: (objIdx: number, keyIdx: number, valueIdx: number) => {
      const obj = objectBuffer[objIdx];
      const key = objectBuffer[keyIdx];
      const value = objectBuffer[valueIdx];

      obj[key] = value;
    },

    exitExt: (idx: number) => {
      const value = objectBuffer[idx];

      throw new Error(`Crashed: ${value}`);
    },

    ...wasmImports,
    ...raw,
  };

  const importObject = { env };

  const result = await WebAssembly.instantiateStreaming(
    responsePromise,
    importObject
  );

  const refAny = ref as any;

  refAny.instance = result.instance;
  refAny.abi = result.instance.exports;
  refAny.memory = result.instance.exports.memory;
  refAny.defer = {};

  Object.entries(ref.abi).forEach(([key, value]: [string, WasmFunc]) => {
    refAny.defer[key] = (...t: (number | boolean)[]) =>
      new Promise((resolve) => setTimeout(() => resolve(value(...t)), 0));
  });

  return ref;
};
