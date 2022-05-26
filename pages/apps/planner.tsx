import React from "react";
import Head from "next/head";
import Link from "next/link";
import shallow from "zustand/shallow";
import type { Message, OutMessage } from "src/planner.worker";
import type { Dispatch, SetStateAction } from "react";
import * as GL from "src/webgl";
import type { WebGl } from "src/webgl";
import styles from "./planner.module.css";
import css from "src/util.module.css";
import * as wasm from "src/wasm";
import { useToast, ToastColors } from "src/errors";
import cx from "classnames";
import create from "zustand";

interface PlannerCb {
  initWorker: (workerRef: Worker) => void;
}

interface PlannerState {
  workerRef: Worker | null;

  cb: PlannerCb;
}

const useStore = create<PlannerState>((set, get) => {
  const initWorker = (workerRef: Worker) => set({ workerRef });

  return {
    workerRef: null,

    cb: {
      initWorker,
    },
  };
});

const selectStable = ({ cb, workerRef }: PlannerState) => ({ cb, workerRef });
const useStable = (): Pick<PlannerState, "cb" | "workerRef"> => {
  return useStore(selectStable, shallow);
};

const Planner: React.VFC = () => {
  const { cb, workerRef } = useStable();
  const toast = useToast();

  React.useEffect(() => {
    // Writing this in a different way doesn't work. URL constructor call
    // must be passed directly to worker constructor.
    const worker = new Worker(
      new URL("src/planner.worker.ts", import.meta.url)
    );

    worker.onmessage = (ev: MessageEvent<OutMessage>) => {
      const message = ev.data;
      switch (message.kind) {
        case "initDone":
          break;

        default:
          if (typeof message.data === "string") {
            const color = ToastColors[message.kind] ?? "info";
            toast.add(color, null, message.data);
          }

          console.log(message.data);
          break;
      }
    };

    cb.initWorker(worker);
  }, [cb, toast]);

  return (
    <div className={styles.wrapper}>
      <Head>
        <link
          key="pwa-link"
          rel="manifest"
          href="/apps/planner/planner.webmanifest"
        />

        <meta key="theme-color" name="theme-color" content="#1976D2" />
      </Head>

      <div
        style={{
          height: "100%",
          width: "100%",
          display: "flex",
          flexDirection: "row",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <div className={css.muiButton} style={{ alignSelf: "center" }}>
          Hello World!
        </div>
      </div>
    </div>
  );
};

export default Planner;
