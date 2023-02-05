<script lang="ts" context="module">
  import type { InputMessage as BaseMessage } from "@lib/ts/gamescreen";
  export type InputMessage =
    | BaseMessage
    | { kind: "uploadLevel"; data: any }
    | { kind: "levelDownload"; data: any }
    | { kind: "saveLevel"; data: any };
</script>

<script lang="ts">
  import { onMount } from "svelte";
  import Screen from "@lib/svelte/gamescreen.svelte";
  import MyWorker from "./worker?worker";
  import Toast, { postToast } from "@lib/svelte/errors.svelte";
  import levelUrl from "./levels/simple.txt?url";
  import { get } from "idb-keyval";
  import type { OutMessage } from "./worker";

  const worker = new MyWorker();
  let fileInput: HTMLInputElement | undefined = undefined;
  let defaultLevel = "";

  onMount(() => {
    const req = fetch(levelUrl).then((r) => r.text());
    const levelText = get("level")
      .then((text) => text ?? req)
      .catch(() => {});

    req.then((t) => (defaultLevel = t));

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

  const fileUpload = async (evt: Event) => {
    const target: HTMLInputElement = evt.target as HTMLInputElement;
    const file = target.files?.[0];
    if (!file || !worker) {
      return;
    }

    // clear the current file so that the next submission will also
    // trigger onchange
    target.value = '';

    const data = await file.text();
    worker.postMessage({ kind: "uploadLevel", data });
  };
</script>

<Toast location={"top-right"} />

<Screen {worker}>
  <div slot="overlay">
    <div class="rightColumn">
      <input
        bind:this={fileInput}
        class="fileInput"
        type="file"
        on:change={fileUpload}
      />

      <button
        class="muiButton"
        on:click={() =>
          worker.postMessage({ kind: "uploadLevel", data: defaultLevel })}
      >
        Hard Reset
      </button>

      <button
        class="muiButton"
        on:click={() =>
          worker.postMessage({ kind: "levelDownload", data: undefined })}
      >
        Save
      </button>

      <button
        class="muiButton"
        on:click={() => fileInput?.click()}
      >
        Open
      </button>
    </div>
  </div>
</Screen>

<style lang="postcss">
  @import "@lib/svelte/button.module.css";

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
