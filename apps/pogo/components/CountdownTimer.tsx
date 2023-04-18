import React from "react";
import "@robinplatform/toolkit/styles.css";
import "./timer.css";
import { create } from "zustand";
import { EditSvg } from "./EditableField";

// I'm not handling errors in this file, because... oh well. Whatever. Meh.

const useTime = create<{ now: Date }>((set) => {
  const now = new Date();

  function updateTime() {
    set({ now: new Date() });
    setTimeout(updateTime, 1000);
  }

  setTimeout(updateTime, 1000 - now.getMilliseconds());

  return { now };
});

export function useCurrentSecond() {
  return useTime((t) => t);
}

const countdownBoxStyle = {
  column: {
    alignItems: "center",
    position: "relative",
  },
  number: { fontSize: "1rem" },
  label: { fontSize: "0.75rem" },
  arrowUp: {
    position: "absolute",
    top: "-0.5rem",
    height: "0.75rem",
    width: "100%",
    fontSize: "0.75rem",
    textAlign: "center",
  },
  arrowDown: {
    position: "absolute",
    bottom: "0.5rem",
    height: "0.75rem",
    width: "100%",
    fontSize: "0.75rem",
    textAlign: "center",
  },
} as const;

export function CountdownTimer({
  deadline,
  setDeadline,
  disableEditing,
  doneText,
}: {
  deadline: Date;
  setDeadline?: (d: Date) => void;
  disableEditing?: boolean;
  doneText: string;
}) {
  const { now } = useCurrentSecond();
  const [editing, setEditing] = React.useState<boolean>(false);

  const difference = deadline.getTime() - now.getTime();
  const seconds = difference / 1000;
  const minutes = seconds / 60;
  const hours = minutes / 60;
  const days = hours / 24;

  const units = [
    {
      label: "days",
      value: Math.max(Math.floor(days), 0),
      weight: 24 * 60 * 60 * 1000,
    },
    {
      label: "hours",
      value: Math.max(Math.floor(hours % 24), 0),
      weight: 60 * 60 * 1000,
    },
    {
      label: "mins",
      value: Math.max(Math.floor(minutes % 60), 0),
      weight: 60 * 1000,
    },
    {
      label: "secs",
      value: Math.max(Math.floor(seconds % 60), 0),
      weight: 1000,
    },
  ];

  return (
    <div
      className={"row"}
      style={{ gap: "0.5rem", padding: "0.5rem 0.25rem 0.1rem 0.25rem" }}
    >
      {units.map((unit) => (
        <div
          key={unit.label}
          className={"col"}
          style={countdownBoxStyle.column}
        >
          {editing && (
            <button
              disabled={disableEditing}
              className={"hover-button"}
              style={countdownBoxStyle.arrowUp}
              onClick={() =>
                setDeadline?.(new Date(deadline.getTime() + unit.weight))
              }
            >
              +
            </button>
          )}
          <p style={countdownBoxStyle.number}>{unit.value}</p>
          {editing && (
            <button
              disabled={disableEditing}
              className={"hover-button"}
              style={countdownBoxStyle.arrowDown}
              onClick={() =>
                setDeadline?.(new Date(deadline.getTime() - unit.weight))
              }
            >
              -
            </button>
          )}
          <p style={countdownBoxStyle.label}>{unit.label}</p>
        </div>
      ))}

      {setDeadline && (
        <button
          disabled={disableEditing}
          onClick={() => setEditing(!editing)}
          style={{
            alignSelf: "flex-start",

            width: "0.8rem",
            height: "0.8rem",
            padding: 0,

            fontSize: "0.8rem",
            lineHeight: "0.8rem",
            textAlign: "center",

            display: "flex",
            flexDirection: "column",
            justifyContent: "center",
            alignItems: "center",
            color: "red",
          }}
        >
          {editing ? <>&#xd7;</> : <EditSvg />}
        </button>
      )}
    </div>
  );
}
