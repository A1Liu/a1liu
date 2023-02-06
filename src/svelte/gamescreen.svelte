<script lang="ts">
  import { onMount } from "svelte";
  import { KeyId, type InputMessage } from "@lib/ts/gamescreen";
  import type { WorkerRef } from "@lib/ts/util";

  type T = $$Generic;
  type O = $$Generic;

  export let worker: WorkerRef<T | InputMessage, O>;
  export let canvas: HTMLCanvasElement | undefined = undefined;
  let overlay: any = undefined;

  const listener = (evt: any) => {
    if (!canvas) return;

    const width = canvas.clientWidth;
    const height = canvas.clientHeight;
    worker.postMessage({ kind: "resize", data: [width, height] });
  };

  $: workerRef = worker.ref;

  $: {
    if (workerRef && canvas) {
      listener(null);

      const offscreen = canvas.transferControlToOffscreen();
      workerRef.postMessage({ kind: "canvas", data: offscreen }, [offscreen]);
    }
  }

  onMount(() => {
    overlay.focus();

    window.addEventListener("resize", listener);
    return () => window.removeEventListener("resize", listener);
  });

  const n2 = (x: number, y: number): [number, number] => [x, y];
</script>

<div
  class="wrapper"
  on:wheel={(evt) => {
    if (!canvas || !worker) return;
    if (evt.target !== overlay) return;

    evt.preventDefault();

    const data = n2(evt.deltaX, evt.deltaY);
    worker.postMessage({ kind: "scroll", data });
  }}
  on:mousemove={(evt) => {
    if (!canvas || !worker) return;
    if (evt.target !== overlay) return;

    const data = n2(evt.clientX, evt.clientY);
    worker.postMessage({ kind: "mousemove", data });
  }}
  on:click={(evt) => {
    if (!canvas || !worker) return;
    if (evt.target !== overlay) return;

    const data = n2(evt.clientX, evt.clientY);
    worker.postMessage({ kind: "leftclick", data });
  }}
  on:contextmenu={(evt) => {
    if (!canvas || !worker) return;
    if (evt.target !== overlay) return;

    evt.preventDefault();

    const data = n2(evt.clientX, evt.clientY);
    worker.postMessage({ kind: "rightclick", data });
  }}
  on:keydown={(evt) => {
    if (evt.repeat || evt.isComposing || evt.keyCode === 229) return;
    if (evt.ctrlKey || evt.metaKey) return;

    if (!canvas || !worker) return;
    if (evt.target !== overlay) return;

    const data = KeyId[evt.code] ?? 0;
    console.log("keydown", data);
    worker.postMessage({ kind: "keydown", data });
  }}
  on:keyup={(evt) => {
    if (evt.isComposing || evt.keyCode === 229) return;
    if (evt.ctrlKey || evt.metaKey) return;

    if (!canvas || !worker) return;
    if (evt.target !== overlay) return;

    const data = KeyId[evt.code] ?? 0;
    worker.postMessage({ kind: "keyup", data });
  }}
>
  <canvas bind:this={canvas} />

  <!-- tabindex allows the div to receive focus, which then allows keydown,
        keyup, etc. etc. -->
  <div
    bind:this={overlay}
    class="overlay"
    tabindex="-1"
    on:mousedown={(evt) => evt.preventDefault()}
  >
    <slot name="overlay" />
  </div>
</div>

<style lang="postcss">
  .wrapper {
    height: 100%;
    width: 100%;
    max-height: 100%;
    max-width: 100%;

    display: flex;
    flex-direction: row;
    flex-wrap: nowrap;
  }

  canvas {
    height: 100%;
    width: 100%;
  }

  .overlay {
    position: fixed;
    z-index: 10;
    top: 0px;
    left: 0px;
    width: 100%;
    height: 100%;

    overflow: hidden;
    display: flex;
    flex-direction: column;

    cursor: default;
    outline: 0px solid transparent;
  }
</style>
