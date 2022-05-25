import React from "react";
import { Scroll } from "./util";
import cx from "classnames";
import css from "./util.module.css";

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
