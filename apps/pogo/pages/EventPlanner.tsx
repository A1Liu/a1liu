import { useRpcQuery } from '@robinplatform/toolkit/react/rpc';
import React from 'react';
import { ScrollWindow } from '../components/ScrollWindow';
import { SelectPage } from '../components/PageState';
import { getUpcomingEventsRpc, PogoEvent } from '../server/leekduck.server';

// Should be able to:
// Lock a pokemon to an event
// Search for pokemon that are good for the specific event
// Project out mega evolutions properly, including energy spend and daily level up limit

// Idea:
// View mega pokemon evolutions in line with events; time moves
// downwards from today, and mega evolution projections are shown speculatively.

// Step 1 is just to do mega evolutions, and some kind of format for planned activities

function Event({ event }: { event: PogoEvent }) {
	return (
		<div
			className={'robin-rounded robin-pad'}
			style={{ border: '1px solid black' }}
		>
			{JSON.stringify(event)}
		</div>
	);
}

export function EventPlanner() {
	const { data: upcomingEvents } = useRpcQuery(getUpcomingEventsRpc, {});

	return (
		<div className={'col full robin-rounded robin-gap robin-pad'}>
			<div className={'row robin-gap'} style={{ flexWrap: 'wrap' }}>
				<SelectPage />
			</div>

			<ScrollWindow
				className="full"
				style={{ backgroundColor: 'white' }}
				innerClassName="col robin-gap"
			>
				{upcomingEvents?.map((event) => (
					<Event key={event.eventID} event={event} />
				))}
			</ScrollWindow>
		</div>
	);
}
