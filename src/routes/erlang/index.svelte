<script lang="ts">
  import { onMount } from "svelte";
  import Screen from "@lib/svelte/gamescreen.svelte";
  import MyWorker from "./worker?worker";
  import Toast, { postToast } from "@lib/svelte/errors.svelte";
  import levelUrl from "./levels/level.txt?url";
  import * as wasm from "@lib/ts/wasm";

  let worker = undefined;
  let fileInput = undefined;

  const levelText = fetch(levelUrl)
    .then((r) => r.text())
    .catch(() => {});

  onMount(() => {
    worker = new MyWorker();

    worker.onmessage = (ev: MessageEvent<OutMessage>) => {
      const message = ev.data;
      switch (message.kind) {
        case "initDone": {
          levelText.then((data) =>
            worker.postMessage({ kind: "uploadLevel", data })
          );
          break;
        }

        case "levelDownload": {
          const blob = new Blob([message.data], { type: "text" });

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
  <div slot="overlay">
    <div class="rightColumn">
      <input
        bind:this={fileInput}
        class="fileInput"
        type="file"
        on:change={(evt) => {
          const file = evt.target.files[0];
          if (!file) return;

          // clear the current file so that the next submission will also
          // trigger onchange
          evt.target.value = null;

          file.text().then((data) => {
            worker.postMessage({ kind: "uploadLevel", data });
          });
        }}
      />

      <button
        class="muiButton"
        on:click={() =>
          worker.postMessage({ kind: "levelDownload", data: undefined })}
      >
        Save
      </button>

      <button
        class="muiButton"
        on:click={() => {
          fileInput.click();
        }}
      >
        Open
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
