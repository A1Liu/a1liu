<script lang="ts" context="module">
  export type InputMessage =
    | { kind: "resize"; data: Number2 }
    | { kind: "scroll"; data: Number2 }
    | { kind: "mousemove"; data: Number2 }
    | { kind: "leftclick"; data: Number2 }
    | { kind: "rightclick"; data: Number2 }
    | { kind: "keydown"; data: number }
    | { kind: "keyup"; data: number }
    | { kind: "canvas"; offscreen: any };

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
  };
</script>

<script lang="ts">
  import { onMount } from "svelte";

  export let worker;
  export let canvas: any = undefined;

  const listener = (evt: any) => {
    if (!worker || !canvas) return;

    const width = canvas.clientWidth;
    const height = canvas.clientHeight;
    worker.postMessage({ kind: "resize", data: [width, height] });
  };

  $: {
    if (worker && canvas) {
      listener(null);

      const offscreen = canvas.transferControlToOffscreen();
      worker.postMessage({ kind: "canvas", offscreen }, [offscreen]);
    }
  }

  onMount(() => {
    canvas.focus();

    window.addEventListener("resize", listener);
    return () => window.removeEventListener("resize", listener);
  });
</script>

<div
  on:wheel={(evt) => {
    if (!canvas || !worker) return;
    if (evt.target !== canvas) return;

    evt.preventDefault();

    const data = [evt.deltaX, evt.deltaY];
    worker.postMessage({ kind: "scroll", data });
  }}
  on:mousemove={(evt) => {
    if (!canvas || !worker) return;
    if (evt.target !== canvas) return;

    const data = [evt.clientX, evt.clientY];
    worker.postMessage({ kind: "mousemove", data });
  }}
  on:click={(evt) => {
    if (!canvas || !worker) return;
    if (evt.target !== canvas) return;

    const data = [evt.clientX, evt.clientY];
    worker.postMessage({ kind: "leftclick", data });
  }}
  on:contextmenu={(evt) => {
    if (!canvas || !worker) return;
    if (evt.target !== canvas) return;

    evt.preventDefault();

    const data = [evt.clientX, evt.clientY];
    worker.postMessage({ kind: "rightclick", data });
  }}
  on:keydown={(evt) => {
    if (evt.repeat || evt.isComposing || evt.keyCode === 229) return;
    if (evt.ctrlKey || evt.metaKey) return;

    if (!canvas || !worker) return;
    if (evt.target !== canvas) return;

    const data = KeyId[evt.code] ?? 0;
    worker.postMessage({ kind: "keydown", data });
  }}
  on:keyup={(evt) => {
    if (evt.isComposing || evt.keyCode === 229) return;
    if (evt.ctrlKey || evt.metaKey) return;

    if (!canvas || !worker) return;
    if (evt.target !== canvas) return;

    const data = KeyId[evt.code] ?? 0;
    worker.postMessage({ kind: "keyup", data });
  }}
>
  <canvas
    bind:this={canvas}
    contentEditable
    on:mousedown={(evt) => evt.preventDefault()}
  />

  <slot />
</div>

<style lang="postcss">
  div {
    height: 100vh;
    width: 100vw;
    max-height: 100vh;
    max-width: 100vw;

    display: flex;
    flex-direction: row;
    flex-wrap: nowrap;
  }

  canvas {
    height: 100%;
    min-width: 0px;
    width: inherit;
    max-width: inherit;
    flex-grow: 1;

    cursor: default;
    outline: 0px solid transparent;
  }
</style>
