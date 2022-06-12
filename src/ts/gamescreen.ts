import * as wasm from "@lib/ts/wasm";
import { WorkerCtx } from "@lib/ts/util";

export type Number2 = [number, number];

export interface Message {
  kind: string;
  data: any;
}

export type InputMessage =
  | { kind: "resize"; data: Number2 }
  | { kind: "scroll"; data: Number2 }
  | { kind: "mousemove"; data: Number2 }
  | { kind: "leftclick"; data: Number2 }
  | { kind: "rightclick"; data: Number2 }
  | { kind: "keydown"; data: number }
  | { kind: "keyup"; data: number }
  | { kind: "canvas"; data: any };

export const KeyId: Record<string, number> = {
  Space: 32,

  Comma: 44,
  Period: 46,
  Slash: 47,

  Digit0: 48,
  Digit1: 49,
  Digit2: 50,
  Digit3: 51,
  Digit4: 52,
  Digit5: 53,
  Digit6: 54,
  Digit7: 55,
  Digit8: 56,
  Digit9: 57,

  Semicolon: 59,

  KeyA: 65,
  KeyB: 66,
  KeyC: 67,
  KeyD: 68,
  KeyE: 69,
  KeyF: 70,
  KeyG: 71,
  KeyH: 72,
  KeyI: 73,
  KeyJ: 74,
  KeyK: 75,
  KeyL: 76,
  KeyM: 77,
  KeyN: 78,
  KeyO: 79,
  KeyP: 80,
  KeyQ: 81,
  KeyR: 82,
  KeyS: 83,
  KeyT: 84,
  KeyU: 85,
  KeyV: 86,
  KeyW: 87,
  KeyX: 88,
  KeyY: 89,
  KeyZ: 90,

  ArrowUp: 128,
  ArrowDown: 129,
  ArrowLeft: 130,
  ArrowRight: 131,
};

const resize = (wasmRef: wasm.Ref, ctx: any, width: number, height: number) => {
  if (!ctx || !ctx.canvas) return;

  // Check if the canvas is not the same size.
  const needResize = ctx.canvas.width !== width || ctx.canvas.height !== height;

  if (needResize) {
    // Make the canvas the same size
    ctx.canvas.width = width;
    ctx.canvas.height = height;

    if (ctx.viewport) {
      ctx.viewport(0, 0, ctx.canvas.width, ctx.canvas.height);
    }
    wasmRef.abi.setDims(width, height);

    // ctx.viewport(0, 0, ctx.canvas.width, ctx.canvas.height);
  }
};

export const handleInput = (
  wasmRef: wasm.Ref,
  ctx: any,
  msg: Message
): boolean => {
  switch (msg.kind) {
    case "scroll": {
      const [x, y] = msg.data;
      wasmRef.abi.onScroll(x, y);
      break;
    }

    case "mousemove": {
      const [x, y] = msg.data;
      wasmRef.abi.onMove(x, y);
      break;
    }

    case "leftclick": {
      const [x, y] = msg.data;
      wasmRef.abi.onClick(x, y);
      break;
    }

    case "rightclick": {
      const [x, y] = msg.data;
      wasmRef.abi.onRightClick(x, y);
      break;
    }

    case "keydown":
    case "keyup": {
      const down = msg.kind === "keydown";
      wasmRef.abi.onKey(down, msg.data);

      const data = `${msg.kind}: ${msg.data}`;
      // postMessage({ kind: "info", data });
      break;
    }

    case "resize": {
      const [width, height] = msg.data;
      resize(wasmRef, ctx, width, height);
      break;
    }

    default:
      return false;
  }

  return true;
};
