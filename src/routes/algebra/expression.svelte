<script lang="ts" context="module">
  import { writable } from "svelte/store";

  type ExprInfo = {
    kind: string;
    paren: boolean;
    implicit?: boolean;
    left?: number;
    right?: number;
    value: string;
    evalValue?: number;
  };

  export const tree = new Map<number, ExprInfo>();

  const ShouldPrintValue: Record<string, true> = {
    integer: true,
    variable: true,
  };

  interface Ctx {
    selected: Map<number, boolean>;
    variables: Map<string, number>;
  }

  function newCtx(): Ctx {
    return {
      selected: new Map(),
      variables: new Map(),
    };
  }

  function createCtx() {
    const { subscribe, set, update } = writable(newCtx());

    return {
      subscribe,

      resetSelected: () =>
        update((prev) => {
          return {
            ...prev,
            selected: new Map(),
          };
        }),

      updateVariable: (name: string, value: number) =>
        update((prev) => {
          prev.variables.set(name, value);

          return { ...prev };
        }),

      select: (id: number) =>
        update((prev) => {
          const selected = prev.selected;
          selected.set(id, !selected.get(id));

          return { ...prev };
        }),

      click: (id: number) =>
        update((prev) => {
          return {
            ...prev,
            selected: new Map([[id, true]]),
          };
        }),
    };
  }

  export const globalCtx = createCtx();
</script>

<script lang="ts">
  import { onMount } from "svelte";

  export let selectedMessage = false;
  export let id: number;

  let selected = false;
  let childSelected = false;
  let leftSelected = false;
  let rightSelected = false;

  $: {
    selected = !!$globalCtx.selected.get(id);
    childSelected = leftSelected && rightSelected;
    selectedMessage = leftSelected || rightSelected || selected;
  }

  $: info = tree.get(id);
</script>

{#if info}
  <span
    class:selected={selected || childSelected}
    class:clickSelected={selected}
    class:childSelected={!selected && childSelected}
    class={`expr${info.kind}`}
    on:mousedown={(evt) => evt.preventDefault()}
  >
    {#if info.paren}
      (
    {/if}

    {#if info.left !== undefined}
      <svelte:self id={info.left} bind:selectedMessage={leftSelected} />
    {/if}

    <!--
    The on:keydown is for A11y; I don't understand what it's for right now,
    but hopefully I'll understand soon enough.
                                  - Albert Liu, Feb 04, 2023 Sat 23:48
    -->
    <div
      class="expr"
      class:implicit={info.implicit}
      on:keydown={(e) => e.preventDefault()}
      on:click={(evt) => {
        if (evt.shiftKey) {
          globalCtx.select(id);
        } else {
          globalCtx.click(id);
        }
      }}
    >
      {#if ShouldPrintValue[info.kind]}
        {info.value}
      {:else}
        {info.kind}
      {/if}
    </div>

    {#if info.right !== undefined}
      <svelte:self id={info.right} bind:selectedMessage={rightSelected} />
    {/if}

    {#if info.paren}
      )
    {/if}
  </span>
{/if}

<style lang="postcss">
  span {
    display: flex;
    flex-direction: row;
    align-items: center;

    gap: 2px;
    padding-left: 2px;
    padding-right: 2px;
  }

  .expr {
    font-size: 36px;
    line-height: 1.2;

    display: flex;
    flex-direction: row;
    align-items: center;

    border-radius: 4px;
    padding: 0px 3px 0px 3px;
  }

  .implicit {
    font-size: 16px;
    padding: 0px;
  }

  .selected {
    padding-left: 2px;
    padding-right: 2px;
    border-radius: 4px;
  }

  .clickSelected {
    margin: 2px;
    background-color: lightblue;
  }

  .childSelected {
    background-color: lightgreen;
  }
</style>
