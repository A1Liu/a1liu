<script lang="ts">
  import { onMount } from "svelte";
  import MyWorker from "./worker?worker";
  import Toast, { ToastColors, addToast } from "@lib/svelte/errors.svelte";
  import * as wasm from "@lib/ts/wasm";

  let worker = undefined;
  let canvas: any = undefined;

  onMount(() => {
    worker = new MyWorker();

    worker.onmessage = (ev: MessageEvent<OutMessage>) => {
      const message = ev.data;
      switch (message.kind) {
        case "initDone":
          const width = canvas.clientWidth;
          const height = canvas.clientHeight;
          worker.postMessage({ kind: "resize", data: [width, height] });
          break;

        default:
          if (typeof message.data === "string") {
            const color = ToastColors[message.kind] ?? "info";
            addToast(color, null, message.data);
          }

          console.log(message.data);
          break;
      }
    };

    const listener = (evt: any) => {
      const width = canvas.clientWidth;
      const height = canvas.clientHeight;
      worker.postMessage({ kind: "resize", data: [width, height] });
    };

    window.addEventListener("resize", listener);

    const offscreen = canvas.transferControlToOffscreen();
    worker.postMessage({ kind: "canvas", offscreen }, [offscreen]);

    return () => window.removeEventListener("resize", listener);
  });
</script>

<Toast />

<div
  class="wrapper"
  on:mousemove={(evt) => {
    if (!canvas) return;
    if (evt.target !== canvas) return;

    const data = [evt.clientX, evt.clientY];
    worker.postMessage({ kind: "mousemove", data });
  }}
  on:click={(evt) => {
    if (!canvas) return;
    if (evt.target !== canvas) return;

    const data = [evt.clientX, evt.clientY];
    worker.postMessage({ kind: "leftclick", data });
  }}
  on:contextmenu={(evt) => {
    if (!canvas) return;
    if (evt.target !== canvas) return;

    evt.preventDefault();

    const data = [evt.clientX, evt.clientY];
    worker.postMessage({ kind: "rightclick", data });
  }}
  on:keydown={(evt) => {
    if (evt.repeat || evt.isComposing || evt.keyCode === 229) return;

    if (!canvas) return;
    if (evt.target !== canvas) return;

    worker.postMessage({ kind: "keydown", data: evt.keyCode });
  }}
  on:keyup={(evt) => {
    if (evt.isComposing || evt.keyCode === 229) return;

    if (!canvas) return;
    if (evt.target !== canvas) return;

    worker.postMessage({ kind: "keyup", data: evt.keyCode });
  }}
>
  <canvas
    bind:this={canvas}
    class="canvas"
    contentEditable
    on:doubleclick={(evt) => {
      evt.stopPropagation();
      evt.preventDefault();
    }}
  />
</div>

<style lang="postcss">
  @import "@lib/svelte/util.module.css";

  .wrapper {
    height: 100vh;
    width: 100vw;
    max-height: 100vh;
    max-width: 100vw;

    display: flex;
    flex-direction: row;
    flex-wrap: nowrap;
  }

  .canvas {
    height: 100%;
    min-width: 0px;
    width: inherit;
    max-width: inherit;
    flex-grow: 1;

    cursor: default;
    outline: 0px solid transparent;
  }
</style>
