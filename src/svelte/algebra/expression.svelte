<script lang="ts">
  import { onMount } from "svelte";

  export let tree;
  export let id;

  $: info = tree.get(id);
</script>

<span class={`expr${info.kind}`}>
  {#if info.paren}
    (
  {/if}

  {#if info.left !== undefined}
    <svelte:self {tree} id={info.left} />
  {/if}

  {#if info.kind === "integer"}
    <div>
      {info.value}
    </div>
  {:else}
    <div>{info.kind}</div>
  {/if}

  {#if info.right !== undefined}
    <svelte:self {tree} id={info.right} />
  {/if}

  {#if info.paren}
    )
  {/if}
</span>

<style lang="postcss">
  span {
    display: flex;
    flex-direction: row;
    align-items: center;
    gap: 2px;
    padding-left: 2px;
    padding-right: 2px;
  }

  div {
    font-size: 24px;
  }
</style>
