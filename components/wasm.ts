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
  readonly addObj: (obj: any) => number;
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

const initialObjectBuffer: any[] = ["log", "info", "warn", "error", "success"];

export const fetchWasm = async (
  path: string,
  importData: Imports
): Promise<WasmRef> => {
  const responsePromise = fetch(path);

  const { postMessage, raw } = importData;

  const imports = { postMessage, ...importData.imports };

  // output data
  const objectBuffer = [...initialObjectBuffer];
  const initialLen = initialObjectBuffer.length;

  // input data
  const objectMap = new Map<number, any>();
  let nextObjectId = 0;

  const wasmImports = {} as any;
  Object.entries(imports).forEach(([key, value]: [string, any]) => {
    wasmImports[key] = (...args: number[]) =>
      value(...args.map((idx) => objectBuffer[idx]));
  });

  const ref: WasmRef = {
    instance: {} as any,
    memory: {} as any,
    abi: {} as any,
    defer: {} as any,
    addObj: (data) => {
      const idx = nextObjectId;

      nextObjectId += 1;
      objectMap.set(idx, data);

      return idx;
    },
  };

  const env = {
    stringObjExt: (location: number, size: number): number => {
      const buffer = new Uint8Array(ref.memory.buffer, location, size);

      const str = decoder.decode(buffer);

      const length = objectBuffer.length;
      objectBuffer.push(str);

      return length;
    },

    objMapStringEncodeExt: (idx: number): number => {
      const value = objectMap.get(idx);

      const encodedString = encoder.encode(value);
      objectMap.set(idx, encodedString);

      return encodedString.length;
    },
    readObjMapExt: (idx: number, begin: number): void => {
      const array = objectMap.get(idx);

      const writeTo = new Uint8Array(ref.memory.buffer, begin, array.length);
      writeTo.set(array);

      objectMap.delete(idx);
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
