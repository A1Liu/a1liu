<script lang="ts">
  import { slide } from "svelte/transition";
  import { onMount } from "svelte";
  import { fmtTime } from "@lib/ts/util";
  import MyWorker from "./worker?worker";
  import Toast, { postToast } from "@lib/svelte/errors.svelte";
  import * as wasm from "@lib/ts/wasm";

  let worker = undefined;

  let count = 1000;
  let benchHistory = [];

  let benchId = 0;
  let runningCount = null;
  let start = null;
  let end = null;

  onMount(() => {
    worker = new MyWorker();

    worker.onmessage = (ev: MessageEvent<OutMessage>) => {
      const message = ev.data;
      switch (message.kind) {
        case "initDone": {
          break;
        }

        case "benchStarted": {
          start = message.data;
          end = null;
          break;
        }

        case "benchDone": {
          end = message.data;

          benchHistory = [
            ...benchHistory,
            {
              id: benchId,
              count: runningCount,
              duration: end - start,
            },
          ];

          runningCount = null;
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
    <input type="number" bind:value={count} min="1" />

    <button
      class="muiButton"
      disabled={runningCount !== null}
      on:click={() => {
        if (runningCount !== null) return;
        if (count === null) return;

        runningCount = count;

        worker.postMessage({ kind: "doBench", data: count });
      }}
    >
      run
    </button>

    <div class="col" style="padding-left: 32px">
      {#if start === null}
        <p>Click the run button to benchmark</p>
      {:else if end === null}
        <p>Running...</p>
      {:else}
        <p>Duration: {(end - start).toFixed(3)}</p>
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
  @import "@lib/svelte/util.module.css";

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
