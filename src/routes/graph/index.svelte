<script lang="ts">
  import { onMount } from "svelte";
  import MyWorker from "./worker?worker";
  import Toast, { postToast } from "@lib/svelte/errors.svelte";
  import { get } from "idb-keyval";
  import * as wasm from "@lib/ts/wasm";

  let worker = undefined;

  onMount(() => {
    worker = new MyWorker();

    worker.onmessage = (ev: MessageEvent<OutMessage>) => {
      const message = ev.data;
      switch (message.kind) {
        case "initDone": {
          break;
        }

        default:
          postToast(message.kind, message.data);
          break;
      }
    };
  });
</script>

<Toast location={"top-right"} />

<div class="overlay">
  <div class="rightColumn">
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
