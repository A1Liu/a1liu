<script lang="ts">
  import { onMount } from "svelte";
  import MyWorker from "./worker?worker";
  import Toast, { postToast } from "@lib/svelte/errors.svelte";
  import { get } from "idb-keyval";
  import * as wasm from "@lib/ts/wasm";
  import Expr, { tree } from "@lib/svelte/algebra/expression.svelte";

  let equation = "";
  let worker = undefined;
  let root = undefined;

  $: worker?.postMessage({ kind: "equationChange", data: equation });

  onMount(() => {
    worker = new MyWorker();

    worker.onmessage = (ev: MessageEvent<OutMessage>) => {
      const message = ev.data;
      switch (message.kind) {
        case "initDone": {
          break;
        }

        case "equationChange":
          // console.log("tree", [...tree.entries()]);
          break;

        case "addTreeItem":
          tree.set(message.data.id, message.data);
          break;

        case "delTreeItem":
          // console.log(message);
          tree.delete(message.data);
          break;

        case "setRoot":
          root = message.data;
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
    <div class="exprArea">
      <input type="text" bind:value={equation} />

      {#if root !== undefined}
        <Expr id={root} />
      {/if}
    </div>

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

  .exprArea {
    display: flex;
    flex-direction: row;
    align-items: center;
    gap: 2px;

    padding: 16px;
  }

  input {
    border: 2px solid lightgray;
    border-radius: 8px;
    padding: 4px;
    margin-right: 8px;
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
    left: 0px;
    top: 0px;

    display: flex;
    flex-direction: column;
    padding: 8px;
    gap: 8px;
  }
</style>
