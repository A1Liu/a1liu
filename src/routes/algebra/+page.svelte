<script lang="ts" context="module">
  import type { InputMessage as BaseMessage } from "@lib/ts/gamescreen";

  export type InputMessage =
    | BaseMessage
    | { kind: "equationChange"; data: any }
    | { kind: "variableUpdate"; data: any };
</script>

<script lang="ts">
  import { onMount } from "svelte";
  import MyWorker from "./worker?worker";
  import Toast, { postToast } from "@lib/svelte/errors.svelte";
  import Expr, { tree, globalCtx } from "./expression.svelte";
  import type { OutMessage } from "./worker";

  let equation = "1x(2 + y) + 3 * 4 + 5 / 6 * 7";
  // let equation = "1x";
  let worker: Worker | undefined = undefined;
  let root: number | undefined = undefined;

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
          break;

        case "addTreeItem":
          tree.set(message.data.id, message.data);
          break;

        case "delTreeItem":
          tree.delete(message.data);
          break;

        case "setRoot":
          root = message.data;
          break;

        case "resetSelected":
          globalCtx.resetSelected();
          break;

        case "newVariable":
          globalCtx.updateVariable(message.data, 1);
          break;

        default:
          postToast(message.kind, message.data);
          break;
      }
    };
  });

  const handleInput = (name: string, evt : Event) => {
    const target=  evt.target as HTMLInputElement;
    const value = Number.parseFloat(target.value);

    if (!isNaN(value)) {
      globalCtx.updateVariable(name, value);
      const data = { name, value };
      worker?.postMessage({ kind: "variableUpdate", data });
    }
  }
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

    {#if $globalCtx.selected.size === 1}
      <div>
        Selected Value: {tree.get([...$globalCtx.selected.keys()][0])?.evalValue}
      </div>
    {/if}

    {#if root !== undefined}
    <div>Expression Value: {tree.get(root)?.evalValue}</div>
      {/if}

    <button
      class="muiButton"
      on:click={() => [...tree.entries()].forEach((e) => console.log(...e))}
    >
      Click
    </button>

    {#each [...$globalCtx.variables.keys()] as name (name)}
      <div>
        {name}:
        <input
          type="number"
          value={$globalCtx.variables.get(name)}
          on:input={(evt) => handleInput(name, evt)}
        />
      </div>
    {/each}
  </div>
</div>

<style lang="postcss">
  @import "@lib/svelte/button.module.css";

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
