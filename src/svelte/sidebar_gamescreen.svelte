<script lang="ts">
  import { onMount } from "svelte";
  import { KeyId } from "@lib/ts/gamescreen";

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
      worker.postMessage({ kind: "canvas", data: offscreen }, [offscreen]);
    }
  }

  onMount(() => {
    canvas.focus();

    window.addEventListener("resize", listener);
    return () => window.removeEventListener("resize", listener);
  });
</script>

<div
  class="wrapper"
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
  <canvas bind:this={canvas} />

  <slot />
</div>

<style lang="postcss">
  .wrapper {
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

    /* Painter uses this and the slot to put a sidebar on the right; unclear
     * if that functionality would be useful elsewhere */
    min-width: 0px;
    width: inherit;
    max-width: inherit;
    flex-grow: 1;

    cursor: default;
    outline: 0px solid transparent;
  }
</style>
