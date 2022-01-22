import React from "react";
import cx from "classnames";
import css from "./util.module.css";

export const timeout = (ms: number): Promise<void> =>
  new Promise((res) => setTimeout(res, ms));

export async function post(url: string, data: any): Promise<any> {
  const resp = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(data),
  });

  return resp.json();
}

export async function get(urlString: string, query: any): Promise<any> {
  const url = new URL(urlString);
  url.search = new URLSearchParams(query).toString();

  const resp = await fetch(url.toString());

  return resp.json();
}

type BackgroundColor = "lightGray" | "white";
const backgroundColor = (bg?: BackgroundColor): string | undefined => {
  switch (bg) {
    case "lightGray":
      return css.bgLightGray;
    case "white":
      return css.bgWhite;
    default:
      return undefined;
  }
};

type TagType = "pre" | "div";
interface ScrollProps {
  tag?: TagType;
  height?: React.CSSProperties["height"];
  background?: BackgroundColor;
  flexBox?: boolean;
}

export const Scroll: React.FC<ScrollProps> = ({ children, ...props }) => {
  const style = { height: props.height };
  const outerClass = cx(css.rounded, backgroundColor(props.background));
  const innerClass = cx(css.scrollColImpl, props.flexBox ? css.col : null);

  let inner;
  switch (props.tag) {
    case "pre":
      inner = <pre className={innerClass}>{children}</pre>;
      break;

    case "div":
    default:
      inner = <div className={innerClass}>{children}</div>;
      break;
  }

  return (
    <div className={outerClass} style={style}>
      {inner}
    </div>
  );
};

interface BtnProps {
  propagate?: boolean;
  preventDefault?: boolean;
  background?: BackgroundColor;
  onClick?: () => void;
}

export const Btn: React.FC<BtnProps> = ({ children, ...props }) => {
  const className = cx(css.muiButton, backgroundColor(props.background));

  const clickHandler = (
    evt: React.MouseEvent<HTMLButtonElement, MouseEvent>
  ) => {
    if (!props.propagate) evt.stopPropagation();
    if (!props.preventDefault) evt.preventDefault();

    props.onClick?.();
  };

  return (
    <button className={className} onClick={clickHandler}>
      {children}
    </button>
  );
};
