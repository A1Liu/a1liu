import { useRpcMutation, useRpcQuery } from "@robinplatform/toolkit/react/rpc";
import { CountdownTimer } from "./CountdownTimer";
import { EditField } from "./EditableField";
import {
  Pokemon,
  megaLevelFromCount,
  TypeColors,
  MegaWaitTime,
} from "../domain-utils";
import "./pokemon-info.css";
import {
  fetchDbRpc,
  setPokemonMegaEndRpc,
  setPokemonMegaEnergyRpc,
  deletePokemonRpc,
  setNameRpc,
} from "../server/db.server";
import React from "react";
import { usePageState, useSetPokemon } from "./PageState";
import { TypeIcons } from "./TypeIcons";
import { EvolveButton, MegaCount, MegaIndicator } from "./PokemonInfo/Evolve";

export function PokemonInfo({ pokemon }: { pokemon: Pokemon }) {
  const { data: db } = useRpcQuery(fetchDbRpc, {});
  const { mutate: setMegaEvolveTime, isLoading: setMegaEvolveTimeLoading } =
    useRpcMutation(setPokemonMegaEndRpc);
  const { mutate: setEnergy, isLoading: setEneryLoading } = useRpcMutation(
    setPokemonMegaEnergyRpc
  );
  const { mutate: deletePokemon, isLoading: deletePokemonLoading } =
    useRpcMutation(deletePokemonRpc);
  const { mutate: setName, isLoading: setNameLoading } =
    useRpcMutation(setNameRpc);

  const { setPage } = usePageState();
  const setPokemon = useSetPokemon();

  const dexEntry = db?.pokedex[pokemon.pokedexId];
  if (!dexEntry) {
    return null;
  }

  const megaLevel = megaLevelFromCount(pokemon.megaCount);

  return (
    <div
      className={"robin-rounded robin-pad"}
      style={{
        backgroundColor: "white",
        border: "1px solid black",
      }}
    >
      <div style={{ position: "relative" }}>
        <div
          style={{
            position: "absolute",
            top: "-1.75rem",
            left: "-1.75rem",
          }}
        >
          <MegaIndicator pokemon={pokemon} />
        </div>

        <div
          style={{
            position: "absolute",
            top: "-1.32rem",
            right: "-1.32rem",
          }}
        >
          <EvolveButton dexEntry={dexEntry} pokemon={pokemon} />
        </div>
      </div>

      <div className={"col"} style={{ gap: "0.5rem" }}>
        <div className={"row"} style={{ gap: "0.5rem", flexWrap: "wrap" }}>
          <div className={"row"} style={{ height: "3rem" }}>
            <EditField
              disabled={setNameLoading}
              value={pokemon.name ?? dexEntry.name}
              setValue={(value) => setName({ id: pokemon.id, name: value })}
              parseFunc={(val) => {
                if (!val.trim()) {
                  return undefined;
                }

                return val;
              }}
            >
              <div className={"col"} style={{ position: "relative" }}>
                {pokemon.name && pokemon.name !== dexEntry.name ? (
                  <>
                    <h3>{pokemon.name}</h3>
                    <p
                      style={{
                        opacity: "50%",
                        fontSize: "0.75rem",
                        position: "absolute",
                        left: "-0.5rem",
                        bottom: "-0.5rem",
                        zIndex: 1000,
                        backgroundColor: "lightgray",
                        borderRadius: "4px",
                        padding: "2px",
                      }}
                    >
                      {dexEntry.name}
                    </p>
                  </>
                ) : (
                  <h3>{dexEntry.name}</h3>
                )}
              </div>
            </EditField>
          </div>

          <div className={"row"} style={{ gap: "0.5rem" }}>
            {dexEntry.megaType.map((t) => {
              const Comp = TypeIcons[t.toLowerCase()] ?? TypeIcons.normal;

              return (
                <div
                  key={t}
                  style={{
                    height: "2rem",
                    width: "2rem",
                    borderRadius: "1rem",
                    padding: "0.3rem",
                    backgroundColor: TypeColors[t.toLowerCase()],
                  }}
                >
                  <Comp />
                </div>
              );
            })}
          </div>

          {!!pokemon.megaCount && (
            <CountdownTimer
              doneText="now"
              disableEditing={setMegaEvolveTimeLoading}
              setDeadline={(deadline) =>
                setMegaEvolveTime({
                  id: pokemon.id,
                  newMegaEnd: new Date(
                    deadline.getTime() - MegaWaitTime[megaLevel]
                  ).toISOString(),
                })
              }
              deadline={
                new Date(
                  new Date(pokemon.lastMegaEnd).getTime() +
                    MegaWaitTime[megaLevel]
                )
              }
            />
          )}
        </div>

        <div className={"row"} style={{ gap: "1.25rem", flexWrap: "wrap" }}>
          <div className={"row"} style={{ gap: "0.5rem" }}>
            <p>Level: </p>
            <MegaCount megaCount={pokemon.megaCount} pokemonId={pokemon.id} />
          </div>

          <div className={"row"} style={{ gap: "0.5rem" }}>
            <p>Energy: </p>
            <EditField
              disabled={setEneryLoading}
              value={dexEntry.megaEnergyAvailable}
              setValue={(value) =>
                setEnergy({ pokedexId: dexEntry.number, megaEnergy: value })
              }
              parseFunc={(val) => {
                const parsed = Number.parseInt(val);
                if (Number.isNaN(parsed)) {
                  return undefined;
                }

                return parsed;
              }}
            >
              <p style={{ minWidth: "1rem" }}>{dexEntry.megaEnergyAvailable}</p>
            </EditField>
          </div>
        </div>

        <div className={"row"} style={{ flexWrap: "wrap", rowGap: "1rem" }}>
          <div
            className={"row robin-gap"}
            style={{ justifyContent: "space-between", flexGrow: 1 }}
          >
            <button
              onClick={() => {
                setPage("tables");
                setPokemon(pokemon.id);
              }}
            >
              Tables
            </button>

            {megaLevel !== 3 && (
              <button
                onClick={() => {
                  setPage("levelup");
                  setPokemon(pokemon.id);
                }}
              >
                Planner
              </button>
            )}
          </div>

          <div
            className={"row"}
            style={{ flexGrow: 2, justifyContent: "flex-end" }}
          >
            <button
              disabled={deletePokemonLoading}
              onClick={() => deletePokemon({ id: pokemon.id })}
            >
              Delete
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
