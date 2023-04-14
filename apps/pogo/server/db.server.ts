/// <reference path="./lowdb.d.ts" />

import { z } from 'zod';
import * as fs from 'fs';
import * as path from 'path';
import produce from 'immer';
import * as os from 'os';
import { onAppStart, Topic } from '@robinplatform/toolkit/daemon';
import {
	computeEvolve,
	isCurrentMega,
	PlannedMega,
	Pokemon,
	Species,
} from '../domain-utils';
import { HOUR_MS } from '../math';
import { Low } from 'lowdb';
import { JSONFile } from 'lowdb/node';

export type PageState = z.infer<typeof PageState>;
const PageState = z.object({
	selectedPokemonId: z.string().optional().nullable(),
	selectedPage: z.union([
		z.literal('pokemon'),
		z.literal('planner'),
		z.literal('tables'),
		z.literal('levelup'),
	]),
});

export type PogoDb = z.infer<typeof PogoDb>;
const PogoDb = z.object({
	pokedex: z.record(z.coerce.number(), Species),
	pokemon: z.record(z.string(), Pokemon),
	evolvePlans: z.array(PlannedMega),
	mostRecentMega: z.object({ id: z.string() }).optional(),

	pageState: PageState,
});

const DB_FILE = path.join(os.homedir(), '.a1liu-robin-pogo-db');
const DB = new Low<PogoDb>(new JSONFile(DB_FILE));
const EmptyDb: PogoDb = {
	pokedex: {},
	pokemon: {},
	evolvePlans: [],
	pageState: {
		selectedPage: 'pokemon',
	},
};
DB.data = EmptyDb;

onAppStart(async () => {
	try {
		await DB.read();
		DB.data = PogoDb.parse(DB.data);
	} catch (e) {
		console.log('Failed to read from JSON', e);
	}
});

let dbModifiedTopic = undefined as unknown as Topic<{}>;

onAppStart(async () => {
	dbModifiedTopic = await Topic.createTopic(['pogo'], 'db');
});

export async function withDb(mut: (db: PogoDb) => void) {
	const newDb = produce(DB.data, mut);
	if (newDb !== DB.data) {
		console.log('DB access caused mutation');

		// TODO: don't do this on literally every write. Maybe do it once a second.
		await fs.promises.writeFile(DB_FILE, JSON.stringify(newDb));

		await dbModifiedTopic.publish({}).catch((e) => console.error('err', e));
		DB.data = newDb;
	}

	return newDb;
}

export async function setDbValueRpc({ db }: { db: PogoDb }) {
	return await withDb((prev) => {
		prev.pokedex = db.pokedex;
		prev.pokemon = db.pokemon;
		prev.mostRecentMega = db.mostRecentMega;
		prev.evolvePlans = db.evolvePlans;
		prev.pageState = db.pageState;
	});
}

export async function fetchDbRpc(): Promise<PogoDb> {
	return DB.data ?? EmptyDb;
}

export function getDB(): PogoDb {
	return DB.data ?? EmptyDb;
}

export async function addPokemonRpc({ pokedexId }: { pokedexId: number }) {
	const id = `${pokedexId}-${Math.random()}`;
	const wayBackWhen = new Date(0).toISOString();
	await withDb((db) => {
		db.pokemon[id] = {
			id,
			pokedexId,
			megaCount: 0,

			// This causes some strange behavior but... it's probably fine.
			lastMegaStart: wayBackWhen,
			lastMegaEnd: wayBackWhen,
		};
	});

	return {};
}

export async function evolvePokemonRpc({ id }: { id: string }) {
	await withDb((db) => {
		const pokemon = db.pokemon[id];
		const dexEntry = db.pokedex[pokemon.pokedexId];

		// rome-ignore lint/complexity/useSimplifiedLogicExpression: I'm not fucking applying demorgan's law to this
		if (!pokemon || !dexEntry) return;

		const now = new Date();

		if (isCurrentMega(db.mostRecentMega?.id, pokemon, now)) {
			console.log('Tried to evolve the currently evolved pokemon');
			return;
		}

		const nextData = computeEvolve(now, dexEntry, pokemon);

		dexEntry.megaEnergyAvailable -= Math.min(
			dexEntry.megaEnergyAvailable,
			nextData.megaEnergySpent,
		);

		pokemon.lastMegaStart = nextData.lastMegaStart;
		pokemon.lastMegaEnd = nextData.lastMegaEnd;
		pokemon.megaCount = nextData.megaCount;

		// If there's a pokemon who is set as "mostRecentMega", and they're not the current
		// pokemon we're evolving now, we should try to update their mega time; however,
		// the Math.min prevents any problems with overwriting a stale mega pokemon.
		//
		// It might be possible to write this condition a little cleaner, but for now,
		// this is fine.
		const mostRecentMega = db.pokemon[db.mostRecentMega?.id ?? ''];
		if (mostRecentMega && mostRecentMega.id !== pokemon.id) {
			const prevMegaEnd = new Date(mostRecentMega.lastMegaEnd);
			mostRecentMega.lastMegaEnd = new Date(
				Math.min(now.getTime(), prevMegaEnd.getTime()),
			).toISOString();
		}

		db.mostRecentMega = { id };
	});

	return {};
}

export async function setPokemonMegaEndRpc({
	id,
	newMegaEnd,
}: {
	id: string;
	newMegaEnd: string;
}) {
	await withDb((db) => {
		const pokemon = db.pokemon[id];
		if (!pokemon) return;

		pokemon.lastMegaEnd = newMegaEnd;
		const newMegaDate = new Date(newMegaEnd);

		const newMegaDateEightHoursBefore = new Date(
			newMegaDate.getTime() - 8 * HOUR_MS,
		);

		const lastMegaStartDate = new Date(pokemon.lastMegaStart);
		if (newMegaDate < lastMegaStartDate) {
			pokemon.lastMegaStart = newMegaEnd;
		}
		if (newMegaDateEightHoursBefore > lastMegaStartDate) {
			pokemon.lastMegaStart = newMegaEnd;
		}
	});

	return {};
}

export async function setPokemonMegaCountRpc({
	id,
	count,
}: {
	id: string;
	count: number;
}) {
	await withDb((db) => {
		const pokemon = db.pokemon[id];
		if (!pokemon) return;

		pokemon.megaCount = Math.min(Math.max(count, 0), 30);
	});

	return {};
}

export async function setPokemonMegaEnergyRpc({
	pokedexId,
	megaEnergy,
}: {
	pokedexId: number;
	megaEnergy: number;
}) {
	await withDb((db) => {
		const dexEntry = db.pokedex[pokedexId];
		if (!dexEntry) return;

		dexEntry.megaEnergyAvailable = Math.max(megaEnergy, 0);
	});

	return {};
}

export async function deletePokemonRpc({ id }: { id: string }) {
	await withDb((db) => {
		// rome-ignore lint/performance/noDelete: fucking idiot rule
		delete db.pokemon[id];
	});

	return {};
}

export async function setNameRpc({ id, name }: { id: string; name: string }) {
	await withDb((db) => {
		const pokemon = db.pokemon[id];
		if (!pokemon) return;

		pokemon.name = name;
	});

	return {};
}

export async function setPageStateRpc(pageState: Partial<PageState>) {
	withDb((db) => {
		db.pageState = { ...db.pageState, ...pageState };
	});

	return {};
}
