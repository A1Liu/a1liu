import _ from 'lodash';
import { getDB, PogoDb, withDb } from './db.server';
import { getMegaPokemon } from './pogoapi.server';
import { nextMegaDeadline, Pokemon, Species } from '../domain-utils';

export async function refreshDexRpc() {
	const pokemon = await getMegaPokemon();

	withDb((db) => {
		for (const entry of pokemon) {
			const prev: Species | undefined = db.pokedex[entry.pokemon_id];
			db.pokedex[entry.pokemon_id] = {
				megaEnergyAvailable: prev?.megaEnergyAvailable ?? 0,

				number: entry.pokemon_id,
				name: entry.pokemon_name,
				megaType: entry.type,

				initialMegaCost: entry.first_time_mega_energy_required,
				megaLevel1Cost: entry.mega_energy_required,
				megaLevel2Cost: entry.mega_energy_required / 2,
				megaLevel3Cost: entry.mega_energy_required / 4,
			};
		}
	});

	// We get a crash during JSON parsing if we don't return something here.
	return {};
}

const compareNames = (db: PogoDb, a: Pokemon, b: Pokemon) => {
	const aName = a.name ?? db.pokedex[a.pokedexId]?.name ?? '';
	const bName = b.name ?? db.pokedex[b.pokedexId]?.name ?? '';

	return aName.localeCompare(bName);
};

const compareMegaTimes = (nowTime: number, a: Pokemon, b: Pokemon) => {
	const aDeadline = nextMegaDeadline(
		a.megaCount,
		new Date(a.lastMegaEnd),
	).getTime();
	const bDeadline = nextMegaDeadline(
		b.megaCount,
		new Date(b.lastMegaEnd),
	).getTime();

	return Math.max(aDeadline, nowTime) - Math.max(bDeadline, nowTime);
};

export async function searchPokemonRpc({
	sort,
}: {
	sort: 'name' | 'pokedexId' | 'megaTime' | 'megaLevelUp';
}) {
	const db = getDB();

	const out = Object.values(db.pokemon);
	const now = new Date();
	const nowTime = now.getTime();
	switch (sort) {
		case 'name':
			out.sort((a, b) => compareNames(db, a, b));
			break;
		case 'pokedexId':
			out.sort((a, b) => {
				return a.pokedexId - b.pokedexId;
			});
			break;
		case 'megaTime':
			out.sort((a, b) => {
				const diff = compareMegaTimes(nowTime, a, b);
				if (diff !== 0) {
					return diff;
				}

				return compareNames(db, a, b);
			});
		case 'megaLevelUp':
			out.sort((a, b) => {
				if (a.megaCount < 30 && b.megaCount >= 30) {
					return -1;
				}
				if (a.megaCount >= 30 && b.megaCount < 30) {
					return 1;
				}

				const diff = compareMegaTimes(nowTime, a, b);
				if (diff !== 0) {
					return diff;
				}

				return compareNames(db, a, b);
			});
	}

	return out.map((pokemon) => pokemon.id);
}
