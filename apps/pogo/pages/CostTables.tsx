import { useRpcQuery } from '@robinplatform/toolkit/react/rpc';
import React from 'react';
import { useSelectOption } from '../components/EditableField';
import { ScrollWindow } from '../components/ScrollWindow';
import {
	SelectPage,
	SelectPokemon,
	usePageState,
	useSelectedPokemonId,
} from '../components/PageState';
import { megaCostForTime, MegaWaitDays, MegaWaitTime } from '../domain-utils';
import { arrayOfN, HOUR_MS } from '../math';
import { fetchDbRpc } from '../server/db.server';

// Should be able to:
// Lock a pokemon to an event
// Search for pokemon that are good for the specific event
// Project out mega evolutions properly, including energy spend and daily level up limit

// Idea:
// View mega pokemon evolutions in line with events; time moves
// downwards from today, and mega evolution projections are shown speculatively.

// Step 1 is just to do mega evolutions, and some kind of format for planned activities

function EnergyCostTable({
	megaCost,
	level,
}: {
	megaCost: number;
	level: 1 | 2 | 3;
}) {
	// Track every 2 hours
	const waitHours2 = MegaWaitDays[level] * 8;
	const waitTime = MegaWaitTime[level];

	const slots = arrayOfN(waitHours2 + 1).map((i) => {
		const timeSinceLastMega = i * 3 * HOUR_MS;

		return {
			timeSinceLastMega,
			megaCost: megaCostForTime(megaCost, waitTime, timeSinceLastMega),
		};
	});

	return (
		<div
			className={'robin-rounded robin-pad row'}
			style={{
				width: '100%',
				height: '5rem',
				justifyContent: 'space-between',
			}}
		>
			{slots.map(({ megaCost }, index) => (
				<div
					key={`${index}`}
					style={{
						backgroundColor: 'blue',
						borderRadius: '8px',
						height: '8px',
						width: '8px',
						position: 'relative',
					}}
				>
					{index % 8 === 0 && (
						<>
							<div
								style={{
									position: 'absolute',
									left: '3px',
									top: 'calc(-1rem + 4px)',
									height: '2rem',
									borderLeft: '2px solid black',
								}}
							/>
							<p
								style={{
									position: 'absolute',
									left: '-1rem',
									bottom: '-2rem',
									width: '2.5rem',
									fontSize: '0.9rem',
								}}
							>
								Day {index / 8}
							</p>
						</>
					)}

					{index % 8 === 0 && (
						<p
							style={{
								position: 'absolute',
								left: 'calc(-1rem + 4px)',
								fontSize: '0.9rem',
								top: '-2rem',
								width: '2rem',
								textAlign: 'center',
							}}
						>
							{megaCost}
						</p>
					)}

					{(index % 8 === 1 || index % 8 === 7) && (
						<p
							style={{
								position: 'absolute',
								left: 'calc(-0.5rem + 4px)',
								top: '-1.9rem',
								fontSize: '0.7rem',
								width: '1rem',
								textAlign: 'center',
								display: 'flex',
								flexDirection: 'column',
								justifyContent: 'center',
							}}
						>
							{megaCost}
						</p>
					)}
				</div>
			))}
		</div>
	);
}

const TableRows: { megaCost: number; level: 1 | 2 | 3 }[] = [
	{ megaCost: 20, level: 1 },
	{ megaCost: 40, level: 1 },
	{ megaCost: 60, level: 1 },
	{ megaCost: 80, level: 1 },

	{ megaCost: 10, level: 2 },
	{ megaCost: 20, level: 2 },
	{ megaCost: 30, level: 2 },
	{ megaCost: 40, level: 2 },

	{ megaCost: 5, level: 3 },
	{ megaCost: 10, level: 3 },
	{ megaCost: 15, level: 3 },
	{ megaCost: 20, level: 3 },
];

export function CostTables() {
	const { data: db } = useRpcQuery(fetchDbRpc, {});
	const selectedMonId = useSelectedPokemonId();
	const selectedPokemon =
		db?.pokedex?.[db.pokemon?.[selectedMonId ?? '']?.pokedexId ?? -1];

	return (
		<div className={'col full robin-rounded robin-gap robin-pad'}>
			<div className={'row robin-gap'} style={{ flexWrap: 'wrap' }}>
				<SelectPage />

				<SelectPokemon />
			</div>

			<ScrollWindow
				className="full"
				style={{ backgroundColor: 'white' }}
				innerClassName="col robin-gap"
			>
				{TableRows.filter(
					(row) =>
						!selectedPokemon ||
						selectedPokemon[`megaLevel${row.level}Cost`] === row.megaCost,
				).map((row) => (
					<div
						key={`${JSON.stringify(row)}`}
						className={'robin-rounded col robin-gap'}
						style={{ border: '1px solid black' }}
					>
						<div className={'row robin-pad'} style={{ paddingBottom: 0 }}>
							<h3>
								Level {row.level} with Full Cost of {row.megaCost}
							</h3>
						</div>

						<div className={'row'}>
							<EnergyCostTable megaCost={row.megaCost} level={row.level} />
						</div>
					</div>
				))}
			</ScrollWindow>
		</div>
	);
}
