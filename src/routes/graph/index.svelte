<script lang="ts">
  import { onMount } from "svelte";
  import Screen from "@lib/svelte/gamescreen.svelte";
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

<Screen {worker}>
  <div slot="overlay">
    <div class="rightColumn">
      <button
        class="muiButton"
        on:click={() => worker.postMessage({ kind: "click" })}
      >
        Click
      </button>
    </div>
  </div>
</Screen>

<style lang="postcss">
  @import "@lib/svelte/util.module.css";

  .fileInput {
    display: none;
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
