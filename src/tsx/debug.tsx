import React from "react";
import cx from "classnames";
import css from "./util.module.css";

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

enum RenderKind {
  Mount = "Mount",
  DepChange = "Dependency Change",
  Spurious = "Spurious Render",
}

interface RenderInfo {
  kind: RenderKind;
}

interface DebugRenderProps {
  title: string;
  deps: any[];
}

export const DebugRender: React.VFC<DebugRenderProps> = ({ title, deps }) => {
  const renderRef = React.useRef(1);
  const depChangeRef = React.useRef(0);
  const infoRef = React.useRef([{ kind: RenderKind.Mount } as RenderInfo]);

  const depChanges = depChangeRef.current + 1;
  const incrementDepChanges = React.useCallback(() => {
    const shouldPush = infoRef.current.length < renderRef.current;
    if (shouldPush && depChangeRef.current < depChanges) {
      infoRef.current.push({ kind: RenderKind.DepChange });
      depChangeRef.current = depChanges;
    }
  }, [depChangeRef, infoRef, renderRef, ...deps]); // eslint-disable-line

  const incrementRenders = React.useCallback(() => {
    if (infoRef.current.length < renderRef.current) {
      infoRef.current.push({ kind: RenderKind.Spurious });
    }
  }, [renderRef, infoRef]);

  incrementDepChanges();
  incrementRenders();

  React.useEffect(() => void (renderRef.current += 1));

  return (
    <div className={css.col}>
      <h3>Debugger for {title}</h3>
      <div>
        <b>Renders:</b> {renderRef.current}
        <br />
        <b>Dependency Changes:</b> {depChangeRef.current}
      </div>
      <Scroll height={300} background={"lightGray"} flexBox={true}>
        {infoRef.current.reduceRight((out: JSX.Element[], render, idx) => {
          out.push(
            <div key={idx} className={cx(css.rounded, css.bgWhite)}>
              <h5>{render.kind}</h5>
            </div>
          );

          return out;
        }, [])}
      </Scroll>
    </div>
  );
};
