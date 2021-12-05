import React from "react";
import css from "./util.module.css";
import styles from "./debug.module.css";

interface DebugRenderProps {
  title: string;
  deps: any[];
}

enum RenderKind {
  Mount = "Mount",
  DepChange = "Dependency Change",
  Spurious = "Spurious Render",
}

interface RenderInfo {
  kind: RenderKind;
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
    <div className={styles.debugWrapper}>
      <h3 style={{ margin: "0px" }}>Debugger for {title}</h3>
      <div>
        <b>Renders:</b> {renderRef.current}
        <br />
        <b>Dependency Changes:</b> {depChangeRef.current}
      </div>
      <div className={styles.renderWrapper}>
        {infoRef.current.reduceRight((out: JSX.Element[], render, idx) => {
          out.push(
            <div key={idx} className={styles.renderItem}>
              <h5>{render.kind}</h5>
            </div>
          );

          return out;
        }, [])}
      </div>
    </div>
  );
};
