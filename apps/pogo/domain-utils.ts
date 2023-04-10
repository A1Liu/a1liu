import { z } from 'zod';
import { DAY_MS, HOUR_MS, lerp } from './math';

export type Species = z.infer<typeof Species>;
export const Species = z.object({
	number: z.number(),
	name: z.string(),

	megaEnergyAvailable: z.number(),
	initialMegaCost: z.number(),
	megaLevel1Cost: z.number(),
	megaLevel2Cost: z.number(),
	megaLevel3Cost: z.number(),

	megaType: z.array(z.string()),
});

export type Pokemon = z.infer<typeof Pokemon>;
export const Pokemon = z.object({
	id: z.string(),
	pokedexId: z.number(),
	name: z.string().optional(),
	lastMegaStart: z.string(),
	lastMegaEnd: z.string(),
	megaCount: z.number(),
});

export type PlannedMega = z.infer<typeof PlannedMega>;
export const PlannedMega = z.object({
	id: z.string(), // UUID
	date: z.string(), // ISO time string of the mega start time
	pokemonId: z.string(), // ID of the pokemon to mega
});

export type PokemonMegaValues = {
	megaEnergySpent: number;
	megaCount: number;
	lastMegaStart: string;
	lastMegaEnd: string;
};

export const TypeColors: Record<string, string> = {
	normal: 'gray',
	steel: 'darkslategray',
	ground: 'chocolate',
	dark: 'midnightblue',
	fire: 'orange',
	grass: 'green',
	poison: 'purple',
	flying: 'aqua',
	bug: 'chartreuse',
	psychic: 'lightcoral',
	fairy: 'lightpink',
	rock: 'peru',
	water: 'royalblue',
	dragon: 'SlateBlue',
	fighting: 'Maroon',
	electric: 'gold',
	ice: 'deepskyblue',
	ghost: 'darkslateblue',
};

export const TypeTextColors: Record<string, string> = {
	normal: 'white',
	steel: 'white',
	ground: 'white',
	dark: 'white',
	fire: 'white',
	grass: 'white',
	poison: 'white',
	flying: 'black',
	bug: 'black',
	psychic: 'black',
	fairy: 'black',
	rock: 'white',
	water: 'white',
	dragon: 'white',
	fighting: 'white',
	electric: 'black',
	ice: 'white',
	ghost: 'white',
};

export const MegaRequirements = {
	1: 1,
	2: 7,
	3: 30,
} as const;

export const MegaWaitDays = {
	0: 0,
	1: 7,
	2: 5,
	3: 3,
} as const;

export const MegaWaitTime = {
	0: 0,
	1: 7 * DAY_MS,
	2: 5 * DAY_MS,
	3: 3 * DAY_MS,
} as const;

export function megaLevelFromCount(count: number): 0 | 1 | 2 | 3 {
	switch (true) {
		case count >= 30:
			return 3;

		case count >= 7:
			return 2;

		case count >= 1:
			return 1;

		default:
			return 0;
	}
}

export function nextMegaDeadline(count: number, lastMega: Date): Date {
	return new Date(lastMega.getTime() + MegaWaitTime[megaLevelFromCount(count)]);
}

export function megaCostForSpecies(
	dexEntry: Species,
	megaLevel: 0 | 1 | 2 | 3,
	timeSinceLastMega: number,
): number {
	if (megaLevel === 0) {
		return dexEntry.initialMegaCost;
	}

	let megaCost = 0;
	switch (megaLevel) {
		case 1:
			megaCost = dexEntry.megaLevel1Cost;
			break;
		case 2:
			megaCost = dexEntry.megaLevel2Cost;
			break;
		case 3:
			megaCost = dexEntry.megaLevel3Cost;
			break;
	}

	return megaCostForTime(megaCost, MegaWaitTime[megaLevel], timeSinceLastMega);
}

export function megaCostForTime(
	megaCost: number,
	waitTime: number,
	timeSinceLastMega: number,
) {
	const megaCostProrated = lerp(
		0,
		megaCost,
		Math.min(1, Math.max(0, 1 - timeSinceLastMega / waitTime)),
	);
	return Math.ceil(megaCostProrated);
}

export function isCurrentMega(
	mostRecentMega: string | undefined,
	pokemon: Pokemon,
	now: Date,
) {
	if (!mostRecentMega) {
		return false;
	}

	if (mostRecentMega !== pokemon.id) {
		return false;
	}

	if (new Date(pokemon.lastMegaEnd) < now) {
		return false;
	}

	return true;
}

export function computeEvolve(
	now: Date,
	dexEntry: Species,
	pokemon: Pick<Pokemon, 'lastMegaEnd' | 'lastMegaStart' | 'megaCount'>,
): PokemonMegaValues {
	const megaLevel = megaLevelFromCount(pokemon.megaCount);
	const megaEnergySpent = megaCostForSpecies(
		dexEntry,
		megaLevel,
		now.getTime() - new Date(pokemon.lastMegaEnd).getTime(),
	);

	const prevMegaStart = new Date(pokemon.lastMegaStart);
	const eightHoursFromNow = new Date(now.getTime() + 8 * HOUR_MS);

	const lastMegaStart = now.toISOString();
	const lastMegaEnd = eightHoursFromNow.toISOString();

	// You can only level up once a day
	let megaCount = pokemon.megaCount;
	if (prevMegaStart.toDateString() !== now.toDateString()) {
		megaCount = Math.min(megaCount + 1, 30);
	}

	return {
		megaEnergySpent,
		megaCount,
		lastMegaStart,
		lastMegaEnd,
	};
}
