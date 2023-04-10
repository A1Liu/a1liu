import { create } from 'zustand';
import React from 'react';
import { useRpcMutation, useRpcQuery } from '@robinplatform/toolkit/react/rpc';
import { fetchDbRpc, setPageStateRpc } from '../server/db.server';

const DefaultPage = 'pokemon' as const;

// I'm not handling errors in this file, because... oh well. Whatever. Meh.
const PageTypes = ['pokemon', 'planner', 'tables', 'levelup'] as const;
type PageType = typeof PageTypes[number];
export const usePageState = create<{
	page: PageType;
	setPage: (a: PageType) => void;
}>((set, get) => {
	return {
		page: DefaultPage,
		setPage: (a) => set({ page: a }),
	};
});

export function SelectPage() {
	const { page, setPage } = usePageState();

	return (
		<div className={'col'}>
			<p>Page:</p>
			<select
				value={page}
				onChange={(evt) => setPage(evt.target.value as PageType)}
			>
				{PageTypes.map((page) => (
					<option key={page} value={page}>
						{page}
					</option>
				))}
			</select>
		</div>
	);
}

export function useSelectedPokemonId() {
	const { data: db } = useRpcQuery(fetchDbRpc, {});

	return db?.pageState.selectedPokemonId;
}

export function useSetPokemon() {
	const { mutate: setPokemon } = useRpcMutation(setPageStateRpc, {});

	return React.useCallback(
		(selectedPokemonId: string | null) => setPokemon({ selectedPokemonId }),
		[setPokemon],
	);
}

export function SelectPokemon() {
	const { data: db } = useRpcQuery(fetchDbRpc, {});
	const selectedPokemon = useSelectedPokemonId();
	const setPokemon = useSetPokemon();

	const pokemon = React.useMemo(
		() => Object.values(db?.pokemon ?? {}),
		[db?.pokemon],
	);

	return (
		<div className={'col'}>
			<p>Pokemon:</p>
			<select
				value={selectedPokemon ?? ''}
				onChange={(evt) =>
					evt.target.value ? setPokemon(evt.target.value) : setPokemon(null)
				}
			>
				<option value={''}>Select pokemon...</option>

				{pokemon.map((mon) => (
					<option key={mon.id} value={mon.id}>
						{mon.name && mon.name !== db?.pokedex?.[mon.pokedexId]?.name
							? `${mon.name} (${db?.pokedex?.[mon.pokedexId]?.name})`
							: db?.pokedex?.[mon.pokedexId]?.name}
					</option>
				))}
			</select>
		</div>
	);
}
