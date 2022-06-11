<script lang="ts" context="module">
  import { writable } from "svelte/store";

  export type ToastLocation = "bottom-left" | "top-right";

  interface ToastData {
    color: string;
    text: string;
  }

  // Use Map here, which iterates in insertion order
  const store = writable({ toasts: [], toastId: 0 });

  type ToastColor =
    | "red"
    | "green"
    | "orange"
    | "blue"
    | "error"
    | "warn"
    | "info"
    | "log"
    | "success";

  export const ToastColors: Record<string, ToastColor> = {
    red: "red",
    green: "green",
    blue: "blue",
    orange: "orange",
    error: "red",
    info: "info",
    log: "log",
    success: "success",
    warn: "warn",
  };

  const ColorMap: Record<ToastColor, string> = {
    red: "red",
    green: "green",
    blue: "blue",
    orange: "orange",
    error: "red",
    info: "blue",
    log: "blue",
    success: "green",
    warn: "orange",
  };

  export function addToast(
    kind: ToastColor,
    time: number | null,
    ...toasts: string[]
  ) {
    const color = ColorMap[kind];
    const newToasts = toasts.map((text) => ({ color, text }));
    store.update((state) => {
      const toasts = [...state.toasts, ...newToasts];

      return { toasts, toastId: state.toastId };
    });

    const count = toasts.length;
    setTimeout(() => {
      store.update((state) => ({
        toasts: state.toasts.slice(count),
        toastId: state.toastId + count,
      }));
    }, time ?? 3 * 1000);
  }

  export const postToast = (tag: string, data: any): void => {
    console.log(tag, data);

    if (typeof data === "string" && tag !== "log") {
      addToast(ToastColors[tag] ?? "green", null, data);
    }
  };
</script>

<script lang="ts">
  export let location: ToastLocation = "bottom-left";

  $: ({ toasts, toastId } = $store);
</script>

<div
  class="toastCorner"
  class:toastTop={location.includes("top")}
  class:toastBottom={location.includes("bottom")}
  class:toastLeft={location.includes("left")}
  class:toastRight={location.includes("right")}
>
  <div class="toastContent">
    {#each toasts as { color, text }, idx (idx + toastId)}
      <div class="toast" style={`background-color: ${color}`}>
        {text}
      </div>
    {/each}
  </div>
</div>

<style lang="postcss">
  .toastTop {
    top: 8px;
  }

  .toastBottom {
    bottom: 8px;
  }

  .toastLeft {
    left: 8px;
  }

  .toastRight {
    right: 8px;
  }

  .toastCorner {
    position: fixed;
    z-index: 10000;
    width: 300px;

    overflow: hidden;
    display: flex;
    flex-direction: column-reverse;
    max-height: calc(100vh - 8px);
  }

  .toastContent {
    display: flex;
    flex-direction: column;
    flex-wrap: nowrap;

    gap: 8px;
    padding-left: 4px;
  }

  .toast {
    min-height: 1.5rem;
    width: 100%;

    color: white;
    font-weight: bold;

    padding: 8px 4px 8px 16px;
  }
</style>
