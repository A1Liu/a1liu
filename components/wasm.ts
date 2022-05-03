import { useToastStore, ToastColors } from "./errors";

const initialObjectBuffer: any[] = ["log", "info", "warn", "error", "success"];

export const postToast = (tag: string, data: any): void => {
  const toast = useToastStore.getState().cb;

  console.log(tag, data);

  if (typeof data === "string") {
    toast.add(ToastColors[tag] ?? "green", null, data);
  }
};

const encoder = new TextEncoder();
const decoder = new TextDecoder();

// These could be more advanced but, meh
type WasmFunc = (...data: any[]) => any;
type AsyncWasmFunc = (...data: any[]) => Promise<any>;

export interface Ref {
  readonly instance: any;
  readonly memory: WebAssembly.Memory;
  readonly abi: { readonly [x: string]: WasmFunc };
  readonly defer: { readonly [x: string]: AsyncWasmFunc };

  // Add object to objectMap and return id for the object added
  readonly addObj: (obj: any) => number;
}

interface Imports {
  readonly postMessage: (kind: string, data: any) => void;
  readonly raw?: { readonly [x: string]: WasmFunc };
  readonly imports: { readonly [x: string]: WasmFunc };
}

export const fetchAsset = async (path: string): Promise<Uint8Array> => {
  const resp = await fetch(path);
  const blob = await resp.blob();
  const arrayBuffer = await blob.arrayBuffer();

  return new Uint8Array(arrayBuffer);
};

export const fetchWasm = async (
  path: string,
  importData: Imports
): Promise<Ref> => {
  const resp = fetch(path);

  const { postMessage, raw } = importData;

  const imports = { postMessage, ...importData.imports };

  // output data
  const objectBuffer = [...initialObjectBuffer];

  // input data
  const objectMap = new Map<number, any>();
  let nextObjectId = 0;

  const wasmImports = {} as any;
  Object.entries(imports).forEach(([key, value]: [string, any]) => {
    wasmImports[key] = (...args: number[]) =>
      value(...args.map((idx) => objectBuffer[idx]));
  });

  const addObj = (data: any): number => {
    const idx = nextObjectId;

    nextObjectId += 1;
    objectMap.set(idx, data);

    return idx;
  };

  const ref: Ref = {
    instance: {} as any,
    memory: {} as any,
    abi: {} as any,
    defer: {} as any,
    addObj,
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
    objMapLenExt: (idx: number): number => objectMap.get(idx).length,
    readObjMapBytesExt: (idx: number, begin: number): void => {
      const array = objectMap.get(idx);
      objectMap.delete(idx);

      const writeTo = new Uint8Array(ref.memory.buffer, begin, array.length);
      writeTo.set(array);

      if (objectMap.size === 0) {
        nextObjectId = 0;
      }
    },

    // TODO some kind of pop stack operation that makes full objects or arrays
    // or whatever

    watermarkObj: (idx: number) => objectBuffer.length,
    clearObjBufferForObjAndAfter: (idx: number) => {
      objectBuffer.length = idx;
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

  const result = await WebAssembly.instantiateStreaming(resp, { env });

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
