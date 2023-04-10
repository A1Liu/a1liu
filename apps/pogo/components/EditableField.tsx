import React from 'react';
import './timer.scss';
import { HOUR_MS, lerp } from '../math';
import { DAY_MS } from '../math';

type EditFieldProps<T> = {
	value: T;
	setValue: (t: T) => void;
	parseFunc: (t: string) => T | undefined;
	disabled?: boolean;
	children?: React.ReactNode;
};

export function EditField<T>({
	value,
	setValue,
	disabled,
	parseFunc,
	children,
}: EditFieldProps<T>) {
	const [editing, setEditing] = React.useState<boolean>(false);
	const [valueState, setValueState] = React.useState<string>(`${value}`);

	React.useEffect(() => {
		setValueState(`${value}`);
	}, [value]);

	const parseFuncRef = React.useRef(parseFunc);
	parseFuncRef.current = parseFunc;

	const valueParsed = React.useMemo(
		() => parseFuncRef.current(valueState),
		[valueState],
	);

	return (
		<div className={'row'} style={{ gap: '0.25rem' }}>
			<div className={'row'} style={{ position: 'relative', padding: '4px' }}>
				<div
					style={{
						display: editing ? undefined : 'none',
						position: 'absolute',
						left: 0,
						top: 0,
						bottom: 0,
						right: 0,
					}}
				>
					<input
						type="text"
						value={valueState}
						onChange={(evt) => setValueState(evt.target.value)}
						style={{
							padding: '2px',
							border: '2px solid gray',
							height: '100%',
							width: '100%',
						}}
					/>
				</div>

				{/* We use `visibility` here to ensure that layout still happens, so that
					the box doesn't change shape during editing, but that the
					stuff underneath doesn't overlap visually in the process.
				 */}
				<div style={{ visibility: editing ? 'hidden' : undefined }}>
					{children}
				</div>
			</div>

			<button
				disabled={disabled || valueParsed === undefined}
				style={{
					alignSelf: 'flex-start',

					width: '0.8rem',
					height: '0.8rem',
					padding: 0,

					fontSize: '0.8rem',
					lineHeight: '0.8rem',
					textAlign: 'center',

					display: 'flex',
					flexDirection: 'column',
					justifyContent: 'center',
					alignItems: 'center',
					color: 'red',
				}}
				onClick={() => {
					if (editing) {
						if (valueParsed === undefined) {
							return;
						}

						setValue(valueParsed);
						setEditing(false);
					} else {
						setEditing(true);
					}
				}}
			>
				{editing ? <>&#xd7;</> : <EditSvg />}
			</button>
		</div>
	);
}

export function useSelectOption<T>(options: Partial<Record<number, T>>) {
	const [selectedIndex, setSelected] = React.useState<number>(NaN);

	return {
		selected: options[selectedIndex],
		value: `${selectedIndex}`,
		onChange: (evt: React.ChangeEvent<HTMLSelectElement>) =>
			setSelected(Number.parseInt(evt.target.value)),
	};
}

export function EditSvg() {
	return (
		<svg
			enableBackground="new 0 0 19 19"
			id="Layer_1"
			version="1.1"
			viewBox="0 0 19 19"
			xmlSpace="preserve"
			xmlns="http://www.w3.org/2000/svg"
			xmlnsXlink="http://www.w3.org/1999/xlink"
		>
			<g>
				<path
					d="M8.44,7.25C8.348,7.342,8.277,7.447,8.215,7.557L8.174,7.516L8.149,7.69   C8.049,7.925,8.014,8.183,8.042,8.442l-0.399,2.796l2.797-0.399c0.259,0.028,0.517-0.007,0.752-0.107l0.174-0.024l-0.041-0.041   c0.109-0.062,0.215-0.133,0.307-0.225l5.053-5.053l-3.191-3.191L8.44,7.25z"
					fill="#231F20"
				/>
				<path
					d="M18.183,1.568l-0.87-0.87c-0.641-0.641-1.637-0.684-2.225-0.097l-0.797,0.797l3.191,3.191l0.797-0.798   C18.867,3.205,18.824,2.209,18.183,1.568z"
					fill="#231F20"
				/>
				<path
					d="M15,9.696V17H2V2h8.953l1.523-1.42c0.162-0.161,0.353-0.221,0.555-0.293   c0.043-0.119,0.104-0.18,0.176-0.287H0v19h17V7.928L15,9.696z"
					fill="#231F20"
				/>
			</g>
		</svg>
	);
}

const convertTimeToLerpable = (time: number) => {
	const beginDate = new Date(time);
	beginDate.setHours(0, 0, 1);
	const endDate = new Date(beginDate.getTime() + DAY_MS - 2 * 1000);
	const decimal =
		(time - beginDate.getTime()) / (endDate.getTime() - beginDate.getTime());

	return decimal;
};

export function TimeSlider({
	value,
	setValue,
	disabled,
	displayDate = (d) => d.toLocaleString(),
	positioning = { left: 0, top: '100%' },
}: Omit<EditFieldProps<Date>, 'parseFunc' | 'children'> & {
	displayDate?: (d: Date) => string;
	positioning?: Partial<Pick<React.CSSProperties, 'left' | 'right' | 'top' | 'bottom'>>;
}) {
	const [editing, setEditing] = React.useState<boolean>(false);
	const [valueState, setValueState] = React.useState<string>('0');

	const valueTime = value.getTime();

	React.useEffect(() => {
		const decimal = convertTimeToLerpable(valueTime);
		setValueState(`${decimal}`);
	}, [value]);

	const valueParsed = React.useMemo(() => {
		const parsed = Number.parseFloat(valueState);
		const beginDate = new Date(valueTime);
		beginDate.setHours(0, 0, 1);
		const endDate = new Date(beginDate.getTime() + DAY_MS - 2 * 1000);

		return new Date(lerp(beginDate.getTime(), endDate.getTime(), parsed));
	}, [valueTime, valueState]);

	return (
		<div className={'row'} style={{ gap: '0.25rem' }}>
			<div className={'row'} style={{ position: 'relative', padding: '4px' }}>
				<div
					style={{
						position: 'absolute',
						...positioning,

						display: editing ? 'flex' : 'none',
						gap: '0.5rem',
					}}
				>
					<input
						type="range"
						min="0"
						max="1"
						step="0.01"
						value={valueState}
						onChange={(evt) => setValueState(evt.target.value)}
						style={{
							padding: '2px',
							border: '2px solid gray',
							height: '1rem',
							width: '10rem',
						}}
					/>
				</div>

				<p>{displayDate(editing ? valueParsed : value)}</p>
			</div>

			<div
				className={'col'}
				style={{
					alignSelf: 'flex-start',
				}}
			>
				{!editing && (
					<button
						disabled={disabled || valueParsed === undefined}
						style={{
							width: '0.8rem',
							height: '0.8rem',
							padding: 0,
						}}
						onClick={() => {
							setEditing(true);
						}}
					>
						<EditSvg />
					</button>
				)}

				{editing && (
					<>
						<button
							disabled={disabled || valueParsed === undefined}
							style={{
								width: '0.8rem',
								height: '0.8rem',
								padding: 0,

								fontSize: '0.8rem',
								lineHeight: '0.8rem',
								textAlign: 'center',

								display: 'flex',
								flexDirection: 'column',
								justifyContent: 'center',
								alignItems: 'center',
								color: 'red',
							}}
							onClick={() => {
								setValueState(`${convertTimeToLerpable(valueTime)}`);
								setEditing(false);
							}}
						>
							&#xd7;
						</button>

						<button
							disabled={disabled || valueParsed === undefined}
							style={{
								width: '0.8rem',
								height: '0.8rem',
								padding: 0,

								fontSize: '0.8rem',
								lineHeight: '0.8rem',
								textAlign: 'center',

								display: 'flex',
								flexDirection: 'column',
								justifyContent: 'center',
								alignItems: 'center',
								color: 'green',
							}}
							onClick={() => {
								if (valueParsed === undefined) {
									return;
								}

								setValue(valueParsed);
								setEditing(false);
							}}
						>
							&#x2713;
						</button>
					</>
				)}
			</div>
		</div>
	);
}
