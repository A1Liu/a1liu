<script lang="ts">
  import { onMount } from "svelte";
  import MyWorker from "./worker?worker";
  import Screen from "@lib/svelte/sidebar_gamescreen.svelte";
  import Toast, { addToast, postToast } from "@lib/svelte/errors.svelte";
  import { githubIssueLink } from "@lib/ts/util";

  type String3 = [string, string, string];

  // <input type="color">

  let worker = undefined;
  let canvas = undefined;
  let palette = undefined;

  let color = [0.5, 0.5, 0.5];
  let colorNullable = [0.5, 0.5, 0.5];

  let tool: string = "triangle";

  let mediaRecorder = null;
  let recordingUrl: string | null = null;

  const urlString = githubIssueLink({ title: "Painter: Bug Report" });

  const recordButtonHandler = (evt) => {
    if (navigator.userAgent.indexOf("Firefox") != -1) {
      addToast(
        "warn",
        10 * 1000,
        "Recording on Firefox isn't supported right now"
      );

      return;
    }

    if (mediaRecorder) {
      mediaRecorder.stop();
      mediaRecorder = null;
      return;
    }

    const stream = canvas.captureStream(24);
    mediaRecorder = new MediaRecorder(stream);
    const recordedChunks = [];

    mediaRecorder.ondataavailable = (e) => {
      if (e.data.size > 0) recordedChunks.push(e.data);
    };

    mediaRecorder.onstop = (e) => {
      const blob = new Blob(recordedChunks, { type: "video/webm" });
      if (recordingUrl) {
        URL.revokeObjectURL(recordingUrl);
      }

      recordingUrl = URL.createObjectURL(blob);
    };

    mediaRecorder.start();
  };

  $: {
    const [r, g, b] = color;
    const colorStyle = `rgb(${r * 255}, ${g * 255}, ${b * 255})`;
    if (palette) {
      palette.style.backgroundColor = colorStyle;
      worker.postMessage({ kind: "setColor", data: [r, g, b] });
    }
  }

  $: {
    const [r, g, b] = colorNullable;
    if (colorNullable.every((v) => v !== null)) {
      color = [...colorNullable];
    }
  }

  onMount(() => {
    worker = new MyWorker();

    worker.onmessage = (ev: MessageEvent<OutMessage>) => {
      const message = ev.data;
      switch (message.kind) {
        case "setTool":
          tool = message.data;
          break;

        case "setColor":
          color = message.data;
          colorNullable = message.data;
          break;

        case "initDone":
          const width = canvas.clientWidth;
          const height = canvas.clientHeight;
          worker.postMessage({ kind: "resize", data: [width, height] });
          break;

        default:
          postToast(message.kind, message.data);
          break;
      }
    };
  });
</script>

<Toast />

<Screen {worker} bind:canvas>
  <div class="configBox">
    <div class="config">
      <h3>Painter</h3>

      <button
        class="muiButton"
        on:click={() => worker.postMessage({ kind: "toggleTool" })}
      >
        {tool}
      </button>

      <div class="colorPicker">
        <div bind:this={palette} class="palette" />

        <div class="colorValues">
          {#each colorNullable as val, idx (idx)}
            <div class="floatInWrapper">
              {`${"RGB"[idx]}: `}
              <input
                class="floatInInput"
                type="number"
                bind:value={val}
                min="0"
                max="1"
                step="0.1"
              />

              {#if val === null}
                <button
                  class="floatInButton"
                  on:click={() => {
                    colorNullable[idx] = color[idx];
                  }}
                >
                  reset
                </button>
              {/if}
            </div>
          {/each}
        </div>
      </div>

      <div class="configRow">
        <button class="muiButton" on:click={recordButtonHandler}>
          {mediaRecorder ? "stop" : "record"}
        </button>

        {#if recordingUrl}
          <button
            class="muiButton"
            on:click={() => {
              const a = document.createElement("a");
              a.href = recordingUrl;
              a.download = "recording.webm";
              a.click();
            }}
          >
            Download
          </button>
        {/if}
      </div>

      {#if recordingUrl}
        <video controls autoPlay muted src={recordingUrl} width="100%">
          {"Sorry, your browser doesn't support embedded videos."}
        </video>
      {/if}
    </div>

    <a class="bugReport" target="_blank" rel="noreferrer" href={urlString}>
      Report a bug
    </a>
  </div>
</Screen>

<style lang="postcss">
  @import "@lib/svelte/button.module.css";

  .configBox {
    height: 100%;
    min-width: 400px;
    max-width: 400px;

    display: flex;
    flex-direction: column;
    justify-content: space-between;

    border-left: 4px solid black;
    padding: 8px 4px 16px 8px;
    gap: 8px;
  }

  .config {
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  .configRow {
    display: flex;
    flex-direction: row;
    flex-wrap: nowrap;
    align-items: center;
    gap: 4px;
  }

  .floatInWrapper {
    position: relative;
    width: 100%;

    display: flex;
    flex-direction: row;
    flex-wrap: nowrap;
    align-items: center;
    gap: 4px;
  }

  .floatInInput {
    width: 100%;
    padding: 4px;
    border: 2px solid black;
    border-radius: 8px;

    /* Chrome, Safari, Edge, Opera */
    &::-webkit-outer-spin-button,
    &::-webkit-inner-spin-button {
      -webkit-appearance: none;
      margin: 0;
    }

    /* Firefox */
    &[type="number"] {
      -moz-appearance: textfield;
    }
  }

  .floatInButton {
    font-size: 0.8rem;
    line-height: 1em;
    border-radius: 4px;
    background-color: #ff7276;
    position: absolute;
    right: 8px;
    top: 8px;
    padding: 4px 8px 4px 8px;

    display: flex;
    flex-direction: row;
    align-items: center;
  }

  .colorPicker {
    display: flex;
    flex-direction: row;
    width: 100%;
    gap: 4px;
  }

  .colorValues {
    display: flex;
    flex-direction: column;
    gap: 4px;

    width: 100%;
  }

  .palette {
    border-radius: 8px;
    width: 120px;
    height: inherit;
  }

  .bugReport {
    box-sizing: border-box;
    border-radius: 8px;
    text-decoration: none;
    color: black;
    padding: 8px;
    background: lightblue;

    display: flex;
    justify-content: center;
    align-items: center;
  }
</style>
