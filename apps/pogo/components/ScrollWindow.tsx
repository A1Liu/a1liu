import React from 'react';

const wrapper = {
	position: 'relative',
} as const;

const inner = {
	position: 'absolute',
	inset: 0,

	overflowY: 'scroll',
} as const;

type ScrollWindowProps = {
	className?: string;
	style?: React.CSSProperties;
	innerClassName?: string;
	innerStyle?: React.CSSProperties;
	children?: React.ReactNode;
};

export const ScrollWindow = ({
	className,
	style,
	innerClassName,
	innerStyle,
	children,
}: ScrollWindowProps) => {
	/*  
    The position relative/absolute stuff makes it so that the
    inner div doesn't affect layout calculations of the surrounding div.
    I found this very confusing at first, so here's the SO post that I got it from:

    https://stackoverflow.com/questions/27433183/make-scrollable-div-take-up-remaining-height
    */
	return (
		<div className={className} style={{ ...style, ...wrapper }}>
			<div style={{ ...inner }}>
				{/* Maybe innerClassName and innerStyle aren't necessary, but I like them as a way to reduce
					the indentation level of the caller's children */}
				<div className={innerClassName} style={{ ...innerStyle }}>
					{children}
				</div>
			</div>
		</div>
	);
};
