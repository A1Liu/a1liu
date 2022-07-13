<script lang="ts">
  import { onMount } from "svelte";
  import MyWorker from "./worker?worker";
  import Toast, { postToast } from "@lib/svelte/errors.svelte";
  import * as wasm from "@lib/ts/wasm";

  let worker = undefined;

  let count = 0;

  onMount(() => {
    worker = new MyWorker();

    worker.onmessage = (ev: MessageEvent<OutMessage>) => {
      const message = ev.data;
      switch (message.kind) {
        case "initDone": {
          break;
        }

        case "":
          count += 1;
          break;

        default:
          postToast(message.kind, message.data);
          break;
      }
    };
  });
</script>

<Toast location={"bottom-left"} />

<div />
