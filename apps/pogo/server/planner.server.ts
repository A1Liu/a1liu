import {
  PokemonMegaValues,
  Species,
  Pokemon,
  nextMegaDeadline,
  computeEvolve,
} from "../domain-utils";
import { DAY_MS, arrayOfN, dateString, uuid } from "../math";
import { getDB, withDb } from "./db.server";

// iterate forwards over lock points,
// iterate backwards in time from each lock point
// at the last lock point, iterate forwards in time

// TODO: add something to allow for checking the cost of daily level-ups
// TODO: add data that shows remaining mega energy

export type MegaEvolveEvent = PokemonMegaValues & {
  id?: string;
  title: string;
  date: string;
  megaEnergyAvailable: number;
};

function naiveFreeMegaEvolve(
  now: Date,
  dexEntry: Species,
  state: Pick<Pokemon, "lastMegaEnd" | "lastMegaStart" | "megaCount"> & {
    megaEnergyAvailable: number;
  }
): MegaEvolveEvent[] {
  let { megaCount, lastMegaEnd, lastMegaStart, megaEnergyAvailable } = state;
  const out: MegaEvolveEvent[] = [];

  let currentState = { megaCount, lastMegaEnd, lastMegaStart };
  while (currentState.megaCount < 30) {
    const deadline = nextMegaDeadline(
      currentState.megaCount,
      new Date(currentState.lastMegaEnd)
    );

    // Move time forwards until the deadline; however, if the deadline is in the past,
    // because its been a while since the last mega, don't accidentally go back in time.
    now = new Date(Math.max(now.getTime(), deadline.getTime()));

    const result = computeEvolve(now, dexEntry, currentState);
    if (result.megaEnergySpent !== 0) {
      console.warn("naiveFreeMegaEvolve: Found non-zero evolve cost");
    }

    out.push({
      title: "Free Evolve",
      date: now.toISOString(),
      megaEnergyAvailable,
      ...result,
    });

    currentState = {
      megaCount: result.megaCount,
      lastMegaEnd: result.lastMegaEnd,
      lastMegaStart: result.lastMegaStart,
    };
  }

  return out;
}

export type PlannerDay = {
  date: string;
  energyAtStartOfDay: number;
  eventsToday: MegaEvolveEvent[];
};

export async function addPlannedEventRpc({
  pokemonId,
  isoDate,
}: {
  pokemonId: string;
  isoDate: string;
}) {
  const date = new Date(isoDate);

  withDb((db) => {
    if (!db.pokemon[pokemonId]) {
      return {};
    }

    db.evolvePlans.push({
      id: uuid(pokemonId),
      date: date.toISOString(),
      pokemonId,
    });
  });

  return {};
}

export async function deletePlannedEventRpc({ id }: { id: string }) {
  withDb((db) => {
    db.evolvePlans = db.evolvePlans.filter((plan) => plan.id !== id);
  });

  return {};
}

export async function clearPokemonRpc({ pokemonId }: { pokemonId: string }) {
  await withDb((db) => {
    db.evolvePlans = db.evolvePlans.filter(
      (evt) => evt.pokemonId !== pokemonId
    );
  });

  return {};
}

export async function setDateOfEventRpc({
  id,
  isoDate,
}: {
  id: string;
  isoDate: string;
}) {
  await withDb((db) => {
    const evt = db.evolvePlans.find((evt) => evt.id === id);
    if (!evt) {
      return;
    }

    evt.date = new Date(isoDate).toISOString();
  });

  return {};
}

export async function megaLevelPlanForPokemonRpc({
  id,
}: {
  id: string;
}): Promise<PlannerDay[]> {
  const db = getDB();
  const pokemon = db.pokemon[id];
  const dexEntry = db.pokedex[pokemon?.pokedexId ?? -1];

  // rome-ignore lint/complexity/useSimplifiedLogicExpression: idiotic rule
  if (!pokemon || !dexEntry) {
    return [];
  }

  const now = new Date();

  const plans = db.evolvePlans.filter((plan) => {
    const date = new Date(plan.date);
    if (dateString(date) < dateString(now)) {
      return false;
    }

    return plan.pokemonId === id;
  });

  plans.sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());

  let currentState = {
    date: now,
    lastMegaEnd: pokemon.lastMegaEnd,
    lastMegaStart: pokemon.lastMegaStart,
    megaCount: pokemon.megaCount,
    megaEnergyAvailable: dexEntry.megaEnergyAvailable,
  };
  const events: MegaEvolveEvent[] = [];
  for (const plan of plans) {
    const planDate = new Date(plan.date);

    const result = computeEvolve(planDate, dexEntry, currentState);
    const megaEnergyAvailable =
      currentState.megaEnergyAvailable - result.megaEnergySpent;
    events.push({
      title: `Planned Evolve for ${result.megaEnergySpent}`,
      date: plan.date,
      megaEnergyAvailable,
      id: plan.id,
      ...result,
    });

    currentState = {
      ...result,
      megaEnergyAvailable,
      date: new Date(Math.max(planDate.getTime(), currentState.date.getTime())),
    };
  }

  events.push(
    ...naiveFreeMegaEvolve(currentState.date, dexEntry, currentState)
  );

  const timeToLastEvent =
    events.length === 0
      ? 0
      : new Date(events[events.length - 1].date).getTime() - now.getTime();
  const daysToDisplay = Math.max(0, Math.ceil(timeToLastEvent / DAY_MS)) + 4;

  let energyAtStartOfDay = dexEntry.megaEnergyAvailable;
  const out: PlannerDay[] = [];
  for (const dayIndex of arrayOfN(daysToDisplay)) {
    const date = new Date(Date.now() + (dayIndex - 2) * DAY_MS);

    const eventsToday = events.filter(
      (e) => new Date(e.date).toDateString() === date.toDateString()
    );

    const spentToday = eventsToday.reduce(
      (prev, evt) => evt.megaEnergySpent + prev,
      0
    );

    out.push({
      date: date.toISOString(),
      eventsToday,
      energyAtStartOfDay,
    });

    energyAtStartOfDay -= spentToday;
  }

  return out;
}
