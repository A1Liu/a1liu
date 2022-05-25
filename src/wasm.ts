const encoder = new TextEncoder();
const decoder = new TextDecoder();

const initialObjectBuffer: any[] = [
  undefined,
  null,

  "log",
  "info",
  "warn",
  "error",
  "success",

  Uint8Array,
  Float32Array,
];

// These could be more advanced but, meh
type WasmFunc = (...data: any[]) => any;

export interface Ref {
  readonly instance: any;
  readonly memory: WebAssembly.Memory;
  readonly abi: { readonly [x: string]: WasmFunc };

  // Read object from object buffer
  readonly readObj: (id: number) => any;
  // Add object to objectMap and return id for the object added
  readonly addObj: (obj: any) => number;
}

interface Imports {
  readonly postMessage: (kind: string, data: any) => void;
  readonly raw?: (ref: Ref) => { readonly [x: string]: WasmFunc };
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

  const objectBuffer = [...initialObjectBuffer]; // output data
  const objectMap = new Map<number, any>(); // input data
  let nextObjectId = 0;

  const readObj = (id: number): any => objectBuffer[id];

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
    readObj,
    addObj,
  };

  const wasmImports = {} as any;
  Object.entries({ postMessage, ...importData.imports }).forEach(
    ([key, value]: [string, any]) => {
      wasmImports[key] = (...args: number[]) =>
        value(...args.map((idx) => objectBuffer[idx]));
    }
  );

  const env = {
    makeString: (location: number, size: number) => {
      const array = new Uint8Array(ref.memory.buffer, location, size);
      const length = objectBuffer.length;
      objectBuffer.push(decoder.decode(array));

      return length;
    },
    makeView: (ty: number, location: number, size: number) => {
      const ArrayClass = objectBuffer[ty];

      const array = new ArrayClass(ref.memory.buffer, location, size);

      const length = objectBuffer.length;
      objectBuffer.push(array);

      return length;
    },

    objMapStringEncode: (idx: number): number => {
      const value = objectMap.get(idx);

      const encodedString = encoder.encode(value);
      objectMap.set(idx, encodedString);

      return encodedString.length;
    },
    objMapLen: (idx: number): number => objectMap.get(idx).length,
    readObjMapBytes: (idx: number, begin: number): void => {
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

    watermark: (idx: number) => objectBuffer.length,
    setWatermark: (idx: number) => {
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

    exit: (idx: number) => {
      const value = objectBuffer[idx];

      throw new Error(`Crashed: ${value}`);
    },

    ...wasmImports,
    ...raw?.(ref),
  };

  const result = await WebAssembly.instantiateStreaming(resp, { env });

  const refAny = ref as any;

  refAny.instance = result.instance;
  refAny.abi = result.instance.exports;
  refAny.memory = result.instance.exports.memory;

  return ref;
};
