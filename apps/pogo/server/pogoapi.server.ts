import { z } from "zod";
import _ from "lodash";
import fetch from "node-fetch";

// Simple code to perform GET endpoint calls
// This is being done server-side instead of client-side
// because the PoGo API has some interesting behaviors
// like built-in endpoint hashing, so we want to eventually
// cache stuff.
function pogoApiGET<T>(path: string, shape: z.ZodSchema<T>): () => Promise<T> {
  return async () => {
    // TODO: handle caching, etc.
    const resp = await fetch(`https://pogoapi.net/api${path}`);
    const data = await resp.json();
    return shape.parse(data);
  };
}

export const getPreviousCommDays = pogoApiGET(
  "/v1/community_days.json",
  z.array(
    z.object({
      bonuses: z.array(z.string()),
      boosted_pokemon: z.array(z.string()),
      community_day_number: z.number(),
      end_date: z.string(),
      start_date: z.string(),
      event_moves: z.array(
        z.object({
          move: z.string(),
          move_type: z.string(),
          pokemon: z.string(),
        })
      ),
    })
  )
);

export const getRegisteredPokemon = pogoApiGET(
  "/v1/released_pokemon.json",
  z.record(
    z.number(),
    z.object({
      id: z.number(),
      name: z.string(),
    })
  )
);

export const getMegaPokemon = pogoApiGET(
  "/v1/mega_pokemon.json",
  z.array(
    z.object({
      type: z.array(z.string()),
      first_time_mega_energy_required: z.number(),
      cp_multiplier_override: z.number().optional(),
      form: z.string(),
      mega_energy_required: z.number(),
      mega_name: z.string(),
      pokemon_id: z.number(),
      pokemon_name: z.string(),
      stats: z.object({
        base_attack: z.number(),
        base_defense: z.number(),
        base_stamina: z.number(),
      }),
    })
  )
);
