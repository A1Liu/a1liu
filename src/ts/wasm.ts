const encoder = new TextEncoder();
const decoder = new TextDecoder();

const constantObjects: any[] = [
  undefined,
  null,
  true,
  false,

  Uint8Array,
  Float32Array,
];

const initialObjectBuffer: any[] = [
  ...constantObjects,

  "",

  "log",
  "info",
  "warn",
  "error",
  "success",
];

// These could be more advanced but, meh
type WasmFunc = (...data: any[]) => any;

export interface Ref {
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

    postMessage("log", JSON.stringify(data));
    // postMessage("log", data);

    setTimeout(loop, 500);
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
    // These are the indices of jsundefined, jsnull, and jsempty_string
    const foundIndex = constantObjects.indexOf(data);
    if (foundIndex !== -1) {
      return foundIndex;
    }

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

  const updateObj = (objId: number, data: any): void => {
    if (objId < 0) objectMap.set(objId, data);
    else {
      if (objId < initialObjectBuffer.length)
        throw new Error("tried to update an object from the initial buffer");

      objectBuffer[objId] = data;
    }
  };

  const ref: Ref = {
    memory: {} as any,
    abi: {} as any,
    readObj,
    addObj,
  };

  // debugLoop(postMessage, objectBuffer, objectMap);
  const makeRaw = (n: any, isTemp: boolean) => addObj(n, isTemp);

  const env = {
    postMessage: (kind: number, data: number): void => {
      postMessage(ref.readObj(kind), ref.readObj(data));
    },

    awaitHook: (id: number, out: number, ptr: number) => {
      readObj(id).then((result) => {
        const outId = addObj(result, false);
        ref.abi.resumePromise(ptr, out, outId);
      });
    },

    makeArray: (isTemp: boolean) => addObj([], isTemp),
    makeObj: (isTemp: boolean) => addObj({}, isTemp),
    makeNumber: makeRaw,
    makeU32: makeRaw,
    makeBool: makeRaw,
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

    exactExpFloatFormat: (value: number, isTemp: boolean) => {
      return addObj(value.toExponential(), isTemp);
    },
    fixedFormatFloat: (
      value: number,
      decimalPlaces: number,
      isTemp: boolean
    ) => {
      return addObj(value.toFixed(decimalPlaces), isTemp);
    },
    parseFloat: (idx: number) => {
      const value = readObj(idx);
      return Number(value);
    },

    readBytes: (idx: number, begin: number): void => {
      const array = readObj(idx);
      const writeTo = new Uint8Array(ref.memory.buffer, begin, array.length);
      writeTo.set(array);
    },

    // TODO some kind of pop stack operation that makes full objects or arrays
    // or whatever

    watermark: (idx: number) => objectBuffer.length,
    setWatermark: (idx: number) => (objectBuffer.length = idx),

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

    ...raw?.(ref),
  };

  const result = await WebAssembly.instantiateStreaming(resp, { env });

  const refAny = ref as any;

  refAny.abi = result.instance.exports;
  refAny.memory = result.instance.exports.memory;

  return ref;
};
