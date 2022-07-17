<script lang="ts">
  import { onMount } from "svelte";
  import MyWorker from "./worker?worker";
  import Toast, { postToast } from "@lib/svelte/errors.svelte";
  import { get } from "idb-keyval";
  import * as wasm from "@lib/ts/wasm";

  let equation = "";
  let worker = undefined;

  $: {
    if (worker) {
      worker.postMessage({ kind: "equationChange", data: equation });
    }
  }

  onMount(() => {
    worker = new MyWorker();

    worker.onmessage = (ev: MessageEvent<OutMessage>) => {
      const message = ev.data;
      switch (message.kind) {
        case "initDone": {
          break;
        }

        case "equationChange":
          break;

        default:
          postToast(message.kind, message.data);
          break;
      }
    };
  });
</script>

<Toast location={"bottom-left"} />

<div class="overlay">
  <div class="rightColumn">
    <input type="text" bind:value={equation} />

    <button
      class="muiButton"
      on:click={() => worker.postMessage({ kind: "click" })}
    >
      Click
    </button>
  </div>
</div>

<style lang="postcss">
  @import "@lib/svelte/util.module.css";

  input {
    border: 2px solid lightgray;
    border-radius: 8px;
    padding: 4px;
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

  .rightColumn {
    position: fixed;
    right: 0px;
    top: 0px;

    display: flex;
    flex-direction: column;
    padding: 8px;
    gap: 8px;
  }
</style>
