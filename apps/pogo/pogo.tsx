import React from "react";
import "./ext.css";
import { usePageState } from "./components/PageState";
import { EventPlanner } from "./pages/EventPlanner";
import { PokemonManager } from "./pages/PokemonManager";
import { CostTables } from "./pages/CostTables";
import { LevelUpPlanner } from "./pages/LevelUpPlanner";
import { renderApp } from "@robinplatform/toolkit/react";
import { useRpcQuery } from "@robinplatform/toolkit/react/rpc";
import { fetchDbRpc } from "./server/db.server";
import { z } from "zod";
import { useAppTopicQuery } from "@robinplatform/toolkit/react/stream";

function Page() {
  const { page } = usePageState();

  switch (page) {
    case "pokemon":
      return <PokemonManager />;
    case "planner":
      return <EventPlanner />;
    case "tables":
      return <CostTables />;
    case "levelup":
      return <LevelUpPlanner />;
  }
}

// "PoGo" is an abbreviation for Pokemon Go which is well-known in the
// PoGo community.
export function Pogo(): JSX.Element {
  const { refetch } = useRpcQuery(fetchDbRpc, {});
  useAppTopicQuery({
    category: ["pogo"],
    key: "db",
    resultType: z.object({}),
    fetchState: () => {
      return Promise.resolve({ state: 0, counter: 0 });
    },
    reducer: (a, _b) => {
      refetch();
      return a;
    },
  });

  return (
    <>
      <Page />
    </>
  );
}

renderApp(<Pogo />);
