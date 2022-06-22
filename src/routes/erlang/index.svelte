<script lang="ts">
  import { onMount } from "svelte";
  import Screen from "@lib/svelte/gamescreen.svelte";
  import MyWorker from "./worker?worker";
  import Toast, { postToast } from "@lib/svelte/errors.svelte";
  import * as wasm from "@lib/ts/wasm";

  let worker = undefined;
  let fileInput = undefined;

  onMount(() => {
    worker = new MyWorker();

    worker.onmessage = (ev: MessageEvent<OutMessage>) => {
      const message = ev.data;
      switch (message.kind) {
        case "initDone":
          break;

        case "levelDownload": {
          console.log(message.data);
          const blob = new Blob([message.data], { type: "text" });
          blob.text().then((t) => console.log(t));

          const url = URL.createObjectURL(blob);

          const a = document.createElement("a");
          a.href = url;
          a.download = "level.txt";

          document.body.appendChild(a);
          a.click();

          document.body.removeChild(a);
          URL.revokeObjectURL(url);
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
  <div class="columnWrapper" slot="overlay">
    <div class="column" />

    <div class="column">
      <input
        bind:this={fileInput}
        class="fileInput"
        type="file"
        on:change={(evt) => console.log(evt.target.value)}
      />

      <button
        class="muiButton"
        on:click={() =>
          worker.postMessage({ kind: "levelDownload", data: undefined })}
      >
        Download
      </button>

      <button
        class="muiButton"
        on:click={() => {
          fileInput.click();
        }}
      >
        Upload
      </button>
    </div>
  </div>
</Screen>

<style lang="postcss">
  @import "@lib/svelte/util.module.css";

  .fileInput {
    display: none;
  }

  .column {
    display: flex;
    flex-direction: column;
    padding: 8px;
    gap: 8px;
  }

  .columnWrapper {
    display: flex;
    flex-direction: row;
    justify-content: space-between;
  }
</style>
