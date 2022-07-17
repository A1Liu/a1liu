<script lang="ts">
  import { onMount } from "svelte";

  export let tree;
  export let id;

  $: info = tree.get(id);
</script>

{#if info.left !== undefined}
  <svelte:self {tree} id={info.left} />
{/if}

{#if info.kind === "+"}
  <div>+</div>
{:else if info.kind === "integer"}
  <div>
    {info.value}
  </div>
{:else}
  ?
{/if}

{#if info.right !== undefined}
  <svelte:self {tree} id={info.right} />
{/if}

<style lang="postcss">
  div {
    font-size: 24px;
  }
</style>
