import { useRpcMutation, useRpcQuery } from "@robinplatform/toolkit/react/rpc";
import { useCurrentSecond } from "../CountdownTimer";
import {
  Species,
  Pokemon,
  megaLevelFromCount,
  megaCostForSpecies,
  MegaWaitTime,
  isCurrentMega,
  MegaRequirements,
} from "../../domain-utils";
import "./pokemon-info.css";
import {
  evolvePokemonRpc,
  fetchDbRpc,
  setPokemonMegaCountRpc,
} from "../../server/db.server";
import React from "react";

export const percentGradient = (fraction: number) =>
  `linear-gradient(to right, transparent, transparent ${
    100 * fraction
  }%, white ${100 * fraction}%)`;
export const MEGA_GRADIENT =
  "linear-gradient(to right, orchid, skyblue, lightgreen, yellow, orange, salmon)";

export function EvolveButton({
  dexEntry,
  pokemon,
}: {
  dexEntry: Species;
  pokemon: Pokemon;
}) {
  const { data: db } = useRpcQuery(fetchDbRpc, {});
  const { now } = useCurrentSecond();
  const megaLevel = megaLevelFromCount(pokemon.megaCount);
  const timeSinceLastMega =
    now.getTime() - new Date(pokemon.lastMegaEnd ?? 0).getTime();
  const megaCost = megaCostForSpecies(dexEntry, megaLevel, timeSinceLastMega);
  const timeSpentAsFraction = Math.max(
    0,
    Math.min(1, timeSinceLastMega / MegaWaitTime[megaLevel])
  );
  const { mutate: megaEvolve, isLoading: megaEvolveLoading } =
    useRpcMutation(evolvePokemonRpc);

  return (
    <div className={"row"} style={{ gap: "0.5rem" }}>
      {megaLevel !== 0 &&
        megaLevel !== 3 &&
        new Date(pokemon.lastMegaStart).toDateString() ===
          now.toDateString() && (
          <p style={{ color: "red", fontWeight: "bold" }}>
            Can't level up again today!
          </p>
        )}

      <button
        style={{
          borderRadius: "0.25rem",
          border: "0.1rem solid black",
          padding: "0.25rem",
          backgroundImage: `${percentGradient(
            timeSpentAsFraction
          )}, ${MEGA_GRADIENT}`,
        }}
        disabled={
          megaEvolveLoading ||
          isCurrentMega(db?.mostRecentMega?.id, pokemon, now) ||
          megaCost > dexEntry.megaEnergyAvailable
        }
        onClick={() => megaEvolve({ id: pokemon.id })}
      >
        Evolve ({megaCost})
      </button>
    </div>
  );
}

export function MegaIndicator({ pokemon }: { pokemon: Pokemon }) {
  const { now } = useCurrentSecond();
  const { data: db } = useRpcQuery(fetchDbRpc, {});

  if (!isCurrentMega(db?.mostRecentMega?.id, pokemon, now)) {
    return null;
  }

  return <div style={{ fontSize: "1.5rem", fontWeight: "bold" }}>M</div>;
}

function ProgressCircle({
  required,
  have,
}: {
  required: number;
  have: number;
}) {
  return (
    <div
      style={{
        overflow: "hidden",
        height: "1.2rem",
        width: "1.2rem",

        borderRadius: "0.7rem",
        border: "2px solid black",

        display: "flex",
        justifyContent: "flex-end",
      }}
    >
      <svg
        viewBox="0 0 100 100"
        style={{
          width: "100%",

          backgroundImage: `${percentGradient(
            Math.min(Math.max(have, 0), required) / required
          )}, ${MEGA_GRADIENT}`,
        }}
      >
        {have >= required && (
          <path
            strokeWidth="20"
            stroke="black"
            d="M 13,45 L 50.071,82.071 M 43,75 L 88,30 z"
          />
        )}
      </svg>
    </div>
  );
}

// https://static.wikia.nocookie.net/robloxpokemonbrickbronze/images/4/42/Megaevo.png/revision/latest/scale-to-width-down/90?cb=20160828021945
export function MegaCount({
  pokemonId,
  megaCount,
}: {
  pokemonId: string;
  megaCount: number;
}) {
  const { mutate: setMegaCount, isLoading: setMegaCountLoading } =
    useRpcMutation(setPokemonMegaCountRpc);
  const megaLevel = megaLevelFromCount(megaCount);

  const [forceVisible, setForceVisible] = React.useState(false);
  const firstRender = React.useRef(true);

  React.useEffect(() => {
    if (firstRender.current) {
      firstRender.current = false;
      return;
    }
    setForceVisible(true);

    const timeout = setTimeout(() => setForceVisible(false), 1000);

    return () => clearTimeout(timeout);
  }, [megaCount]);

  return (
    <div className={"row"} style={{ gap: "0.3rem" }}>
      <button
        style={{
          borderRadius: "1.4rem",
          height: "1rem",
          width: "1rem",

          display: "flex",
          justifyContent: "center",
          alignItems: "center",
        }}
        disabled={setMegaCountLoading}
        onClick={() => setMegaCount({ id: pokemonId, count: megaCount - 1 })}
      >
        -
      </button>

      <div className="pogo-mega-info" style={{ position: "relative" }}>
        <div className={"row"} style={{ gap: "0.2rem" }}>
          <ProgressCircle required={1} have={megaCount} />
          <ProgressCircle required={6} have={megaCount - 1} />
          <ProgressCircle required={23} have={megaCount - 7} />
        </div>

        <div
          className="pogo-mega-info-tooltip"
          style={{
            position: "absolute",
            right: `calc(${Math.max(2 - megaLevel, 0)} * 1.4rem)`,
            bottom: "1rem",

            width: "7rem",

            visibility: forceVisible ? "visible" : undefined,
            opacity: forceVisible ? "1" : undefined,

            paddingBottom: "0.3rem",

            display: "flex",
            justifyContent: "flex-end",
            transition: "0.3s opacity ease, 0.3s visibility ease",
          }}
        >
          <div
            className="robin-rounded"
            style={{
              width: "fit-content",

              padding: "0.2rem",
              opacity: "95%",
              backgroundColor: "black",
              color: "white",
            }}
          >
            {megaLevel < 3
              ? `${MegaRequirements[megaLevel + 1] - megaCount} to level ${
                  megaLevel + 1
                }`
              : "level 3 (max)"}
          </div>
        </div>
      </div>

      <button
        style={{
          borderRadius: "1.4rem",
          height: "1rem",
          width: "1rem",

          display: "flex",
          justifyContent: "center",
          alignItems: "center",
        }}
        disabled={setMegaCountLoading}
        onClick={() => setMegaCount({ id: pokemonId, count: megaCount + 1 })}
      >
        +
      </button>
    </div>
  );
}
