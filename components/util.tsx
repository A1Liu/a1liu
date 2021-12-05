import React from "react";
import css from "./util.module.css";

export const timeout = (ms: number): Promise<void> =>
  new Promise((res) => setTimeout(res, ms));

type TagType = "pre" | "div";
interface ScrollProps {
  tag?: TagType;
  height?: number;
}

export const Scroll: React.FC<ScrollProps> = ({ children, tag, height }) => {
  const style: React.CSSProperties = { height: `${height}px` };

  switch (tag) {
    case "pre":
      return (
        <div className={css.scrollCol} style={style}>
          <pre>{children}</pre>
        </div>
      );
    default:
      return (
        <div className={css.scrollCol} style={style}>
          <div>{children}</div>
        </div>
      );
  }
};

interface BtnProps {
  propagate?: boolean;
  onClick?: () => void;
}

export const Btn: React.FC<BtnProps> = ({ children, onClick, ...props }) => {
  const clickHandler = (evt: React.SyntheticEvent) => {
    const propagate = props.propagate ?? false;
    if (!propagate) evt.stopPropagation();
    onClick?.();
  };

  return (
    <button className={css.muiButton} onClick={clickHandler}>
      {children}
    </button>
  );
};
