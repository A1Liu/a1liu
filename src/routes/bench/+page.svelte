<script lang="ts">
  import { slide } from "svelte/transition";
  import { onMount } from "svelte";
  import { fmtTime,  } from "@lib/ts/util";
  import MyWorker from "./worker?worker";
  import Toast, { postToast } from "@lib/svelte/errors.svelte";
  import type { Message, OutMessage } from "./worker";
  import { WorkerRef } from "@lib/ts/util";

  // import Kilordle from "../kilordle/index.svelte";

  interface BenchEntry {
    id: number;
    count: number;
    duration: number;
  }

  const worker = new WorkerRef<Message, OutMessage>();

  let inputCount = 1000;
  let benchId = 0;
  let benchHistory: BenchEntry[] = [];

  let count: number | null = null;
  let done = 0;
  let start: number | null = null;
  let end: number | null = null;

  onMount(() => {
    worker.init(new MyWorker());
    worker.onmessage = (ev: MessageEvent<OutMessage>) => {
      const message = ev.data;
      switch (message.kind) {
        case "initDone": {
          break;
        }

        case "": {
          done += 32;
          break;
        }

        case "benchStarted": {
          done = 0;
          start = message.data;
          end = null;
          break;
        }

        case "benchDone": {
          if (start === null || count === null) {
            // TODO: warn here, this should never happen
            return;
          }

          const newItem = {
            id: benchId,
            count,
            duration: message.data - start,
          };

          benchHistory = [...benchHistory, newItem];
          end = message.data;
          count = null;
          benchId += 1;
          break;
        }

        default:
          postToast(message.kind, message.data);
          break;
      }
    };
  });
</script>

<Toast location={"bottom-left"} />

<div class="col">
  <div class="row">
    <input type="number" bind:value={inputCount} min="1" />

    <button
      class="muiButton"
      disabled={count !== null}
      on:click={() => {
        if (count !== null) return;
        if (inputCount === null) return;

        count = inputCount;

        worker.postMessage({ kind: "doBench", data: inputCount });
      }}
    >
      run
    </button>

    <div class="col" style="padding-left: 32px">
      {#if start === null}
        <p>Click the run button to benchmark</p>
      {:else if end === null && count !== null}
        <p>Running... {((done / count) * 100).toFixed(2)}%</p>
      {:else if end !== null}
        <p>Duration: {fmtTime(end - start)}</p>
      {/if}
    </div>
  </div>
</div>

<div class="history-box">
  <div class="col" style="flex-direction: column-reverse; gap: 4px">
    {#each benchHistory as info (info.id)}
      <div class="row history-item" transition:slide>
        <p>Count: {info.count}</p>
        <p>Duration: {fmtTime(info.duration)}</p>
      </div>
    {/each}
  </div>
</div>

<style lang="postcss">
  @import "@lib/svelte/button.module.css";

  .history-box {
    height: 100vh;

    padding: 8px;
    position: fixed;
    right: 0px;
    top: 0px;
    overflow-y: scroll;
  }

  .history-item {
    border: 1px solid black;
  }

  .col {
    display: flex;
    flex-direction: column;
  }

  .row {
    display: flex;
    flex-direction: row;
    padding: 8px;
  }
</style>
