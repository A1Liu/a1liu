import { useRpcMutation, useRpcQuery } from '@robinplatform/toolkit/react/rpc';
import { useCurrentSecond, CountdownTimer } from './CountdownTimer';
import { EditField } from './EditableField';
import {
	Species,
	Pokemon,
	megaLevelFromCount,
	megaCostForSpecies,
	TypeColors,
	TypeTextColors,
	MegaWaitTime,
	MegaRequirements,
	isCurrentMega,
} from '../domain-utils';
import './pokemon-info.css';
import {
	evolvePokemonRpc,
	fetchDbRpc,
	setPokemonMegaCountRpc,
	setPokemonMegaEndRpc,
	setPokemonMegaEnergyRpc,
	deletePokemonRpc,
	setNameRpc,
} from '../server/db.server';
import React from 'react';
import { usePageState, useSelectedPokemonId, useSetPokemon } from './PageState';
import { TypeIcons } from './TypeIcons';

function EvolvePokemonButton({
	dexEntry,
	pokemon,
}: {
	dexEntry: Species;
	pokemon: Pokemon;
}) {
	const { data: db } = useRpcQuery(fetchDbRpc, {});
	const { now } = useCurrentSecond();
	const megaLevel = megaLevelFromCount(pokemon.megaCount);
	const megaCost = megaCostForSpecies(
		dexEntry,
		megaLevel,
		now.getTime() - new Date(pokemon.lastMegaEnd ?? 0).getTime(),
	);
	const { mutate: megaEvolve, isLoading: megaEvolveLoading } =
		useRpcMutation(evolvePokemonRpc);

	return (
		<div className={'row'} style={{ gap: '0.5rem' }}>
			{megaLevel !== 0 &&
				megaLevel !== 3 &&
				new Date(pokemon.lastMegaStart).toDateString() ===
					now.toDateString() && (
					<p style={{ color: 'red', fontWeight: 'bold' }}>
						Can't level up again today!
					</p>
				)}

			<button
				style={{ padding: '0' }}
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

function MegaIndicator({ pokemon }: { pokemon: Pokemon }) {
	const { now } = useCurrentSecond();
	const { data: db } = useRpcQuery(fetchDbRpc, {});
	if (!isCurrentMega(db?.mostRecentMega?.id, pokemon, now)) {
		return null;
	}

	return <div style={{ fontSize: '1.5rem', fontWeight: 'bold' }}>M</div>;
}

const megaIconUrl =
	'https://static.wikia.nocookie.net/robloxpokemonbrickbronze/images/4/42/Megaevo.png/revision/latest/scale-to-width-down/90?cb=20160828021945';
function MegaCount({
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

	const progressCircle = ({
		required,
		have,
	}: {
		required: number;
		have: number;
	}) => {
		return (
			<div
				style={{
					overflow: 'hidden',
					borderRadius: '0.6rem',
					height: '1.1rem',
					width: '1.1rem',
					border: '1px solid black',

					backgroundSize: 'cover',
					backgroundPosition: 'center',
					backgroundImage:
						'linear-gradient(to bottom, purple, lightblue, lightgreen, yellow)',

					display: 'flex',
					justifyContent: 'flex-end',
				}}
			>
				<div
					style={{
						width: `calc(${
							100 * (1 - Math.min(Math.max(have, 0), required) / required)
						}%)`,
						background: 'white',
					}}
				/>
			</div>
		);
	};

	// https://static.wikia.nocookie.net/robloxpokemonbrickbronze/images/4/42/Megaevo.png/revision/latest/scale-to-width-down/90?cb=20160828021945

	return (
		<div className={'row'} style={{ gap: '0.4rem' }}>
			<div className="pogo-mega-info" style={{ position: 'relative' }}>
				<div className={'row'} style={{ gap: '0.3rem' }}>
					{progressCircle({ required: 1, have: megaCount })}
					{progressCircle({ required: 6, have: megaCount - 1 })}
					{progressCircle({ required: 23, have: megaCount - 7 })}
				</div>

				<div
					className="pogo-mega-info-tooltip"
					style={{
						position: 'absolute',
						right: `calc(${Math.max(2 - megaLevel, 0)} * 1.4rem)`,
						bottom: '1rem',

						width: '7rem',

						visibility: forceVisible ? 'visible' : undefined,
						opacity: forceVisible ? '1' : undefined,

						paddingBottom: '0.3rem',

						display: 'flex',
						justifyContent: 'flex-end',
						transition: '0.3s opacity ease, 0.3s visibility ease',
					}}
				>
					<div
						className="robin-rounded"
						style={{
							width: 'fit-content',

							padding: '0.2rem',
							opacity: '95%',
							backgroundColor: 'black',
							color: 'white',
						}}
					>
						{megaLevel < 3
							? `${MegaRequirements[megaLevel + 1] - megaCount} to level ${
									megaLevel + 1
							  }`
							: 'level 3 (max)'}
					</div>
				</div>
			</div>

			<div className={'row'} style={{ gap: '0.2rem' }}>
				<button
					style={{ padding: '0.2rem' }}
					disabled={setMegaCountLoading}
					onClick={() => setMegaCount({ id: pokemonId, count: megaCount + 1 })}
				>
					+
				</button>

				<button
					style={{ padding: '0.2rem' }}
					disabled={setMegaCountLoading}
					onClick={() => setMegaCount({ id: pokemonId, count: megaCount - 1 })}
				>
					-
				</button>
			</div>
		</div>
	);
}

export function PokemonInfo({ pokemon }: { pokemon: Pokemon }) {
	const { data: db } = useRpcQuery(fetchDbRpc, {});
	const { mutate: setMegaEvolveTime, isLoading: setMegaEvolveTimeLoading } =
		useRpcMutation(setPokemonMegaEndRpc);
	const { mutate: setEnergy, isLoading: setEneryLoading } = useRpcMutation(
		setPokemonMegaEnergyRpc,
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
			className={'robin-rounded robin-pad'}
			style={{
				backgroundColor: 'white',
				border: '1px solid black',
			}}
		>
			<div style={{ position: 'relative' }}>
				<div
					style={{
						position: 'absolute',
						top: '-1.75rem',
						left: '-1.75rem',
					}}
				>
					<MegaIndicator pokemon={pokemon} />
				</div>

				<div
					style={{
						position: 'absolute',
						top: '-1.20rem',
						right: '-1.20rem',
					}}
				>
					<EvolvePokemonButton dexEntry={dexEntry} pokemon={pokemon} />
				</div>
			</div>

			<div className={'col'} style={{ gap: '0.5rem' }}>
				<div className={'row'} style={{ gap: '0.5rem', flexWrap: 'wrap' }}>
					<div className={'row'} style={{ height: '3rem' }}>
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
							<div className={'col'} style={{ position: 'relative' }}>
								{pokemon.name && pokemon.name !== dexEntry.name ? (
									<>
										<h3>{pokemon.name}</h3>
										<p
											style={{
												opacity: '50%',
												fontSize: '0.75rem',
												position: 'absolute',
												left: '-0.5rem',
												bottom: '-0.5rem',
												zIndex: 1000,
												backgroundColor: 'lightgray',
												borderRadius: '4px',
												padding: '2px',
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

					<div className={'row'} style={{ gap: '0.5rem' }}>
						{dexEntry.megaType.map((t) => {
							const Comp = TypeIcons[t.toLowerCase()] ?? TypeIcons.normal;

							return (
								<div
									key={t}
									style={{
										height: '2rem',
										width: '2rem',
										borderRadius: '1rem',
										padding: '0.3rem',
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
										deadline.getTime() - MegaWaitTime[megaLevel],
									).toISOString(),
								})
							}
							deadline={
								new Date(
									new Date(pokemon.lastMegaEnd).getTime() +
										MegaWaitTime[megaLevel],
								)
							}
						/>
					)}
				</div>

				<div className={'row'} style={{ gap: '1.25rem', flexWrap: 'wrap' }}>
					<div className={'row'} style={{ gap: '0.5rem' }}>
						<p>Level: </p>
						<MegaCount megaCount={pokemon.megaCount} pokemonId={pokemon.id} />
					</div>

					<div className={'row'} style={{ gap: '0.5rem' }}>
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
							<p style={{ minWidth: '1rem' }}>{dexEntry.megaEnergyAvailable}</p>
						</EditField>
					</div>
				</div>

				<div className={'row'} style={{ flexWrap: 'wrap', rowGap: '1rem' }}>
					<div
						className={'row robin-gap'}
						style={{ justifyContent: 'space-between', flexGrow: 1 }}
					>
						<button
							onClick={() => {
								setPage('tables');
								setPokemon(pokemon.id);
							}}
						>
							Tables
						</button>

						{megaLevel !== 3 && (
							<button
								onClick={() => {
									setPage('levelup');
									setPokemon(pokemon.id);
								}}
							>
								Planner
							</button>
						)}
					</div>

					<div
						className={'row'}
						style={{ flexGrow: 2, justifyContent: 'flex-end' }}
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
