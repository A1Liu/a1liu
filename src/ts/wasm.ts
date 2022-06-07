const encoder = new TextEncoder();
const decoder = new TextDecoder();

const initialObjectBuffer: any[] = [
  undefined,
  null,
  "",

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

function debugLoop(
  postMessage: any,
  objectBuffer: any[],
  objectMap: Map<number, any>
) {
  function loop() {
    const data = {
      objectBuffer,
      objectMap: [...objectMap.entries()],
    };
    // postMessage("info", JSON.stringify(data));
    postMessage("info", data);

    setTimeout(loop, 2000);
  }
  loop();
}

export const fetchWasm = async (
  path: string,
  importData: Imports
): Promise<Ref> => {
  const resp = fetch(path);

  const { postMessage, raw } = importData;

  const objectBuffer: any[] = [...initialObjectBuffer]; // output data
  const objectMap = new Map<number, any>(); // input data
  let nextObjectId = -1;

  const readObj = (id: number): any => objectBuffer[id] ?? objectMap.get(id);

  const addObj = (data: any, isTemp: boolean = false): number => {
    if (isTemp) {
      const idx = objectBuffer.length;
      objectBuffer.push(data);

      return idx;
    }

    const idx = nextObjectId;

    nextObjectId -= 1;
    objectMap.set(idx, data);

    return idx;
  };

  const updateObj = (obj: number, data: any): void => {
    if (id < 0) {
      objectMap.set(obj, data);
      return;
    }

    objectBuffer[id] = data;
  };

  const ref: Ref = {
    instance: {} as any,
    memory: {} as any,
    abi: {} as any,
    readObj,
    addObj,
  };

  debugLoop(postMessage, objectBuffer, objectMap);

  const wasmImports = {} as any;
  Object.entries({ postMessage, ...importData.imports }).forEach(
    ([key, value]: [string, any]) => {
      wasmImports[key] = (...args: number[]) => value(...args.map(readObj));
    }
  );

  const env = {
    makeArray: (isTemp: boolean) => addObj([], isTemp),
    makeObj: (isTemp: boolean) => addObj({}, isTemp),
    makeString: (location: number, size: number, isTemp: boolean) => {
      const array = new Uint8Array(ref.memory.buffer, location, size);
      return addObj(decoder.decode(array), isTemp);
    },
    makeView: (ty: number, location: number, size: number, isTemp: boolean) => {
      const ArrayClass = readObj(ty);

      const array = new ArrayClass(ref.memory.buffer, location, size);

      return addObj(array, isTemp);
    },

    encodeString: (idx: number): number => {
      const value = readObj(idx);

      const encodedString = encoder.encode(value);
      updateObj(idx, encodedString);

      return encodedString.length;
    },
    readBytes: (idx: number, begin: number): void => {
      const array = objectMap.get(idx);
      const writeTo = new Uint8Array(ref.memory.buffer, begin, array.length);
      writeTo.set(array);
    },

    // TODO some kind of pop stack operation that makes full objects or arrays
    // or whatever

    watermark: (idx: number) => objectBuffer.length,
    setWatermark: (idx: number) => {
      objectBuffer.length = idx;
    },
    deleteObj: (idx: number) => objectMap.delete(idx),

    objLen: (idx: number): number => readObj(idx).length,
    arrayPush: (arrayIdx: number, valueIdx: number) => {
      const arr = readObj(arrayIdx);
      const value = readObj(valueIdx);

      arr.push(value);
    },
    objSet: (objIdx: number, keyIdx: number, valueIdx: number) => {
      const obj = readObj(objIdx);
      const key = readObj(keyIdx);
      const value = readObj(valueIdx);

      obj[key] = value;
    },

    exit: (idx: number) => {
      const value = readObj(idx);

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
