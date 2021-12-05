import React from "react";
import css from "./util.module.css";
import styles from './debug.module.css';

interface DebugRenderProps {
  title: string;
  deps: any[];
}

enum RenderKind {
  Mount = "Mount",
  DependencyChange = "DependencyChange",
  SpuriousRerender = "SpuriousRerender",
}

interface DebugRenderInfo {
  kind: RenderKind;
}

export const DebugRender: React.VFC<DebugRenderProps> = ({ title, deps }) => {
  const renderRef = React.useRef(1);
  const depChangeRef = React.useRef(0);
  const renderListRef = React.useRef<DebugRenderInfo[]>([
    { kind: RenderKind.Mount },
  ]);

  const depChanges = depChangeRef.current + 1;
  const incrementDepChanges = React.useCallback(() => {
    const shouldPush = renderListRef.current.length < renderRef.current;
    if (shouldPush && depChangeRef.current < depChanges) {
      renderListRef.current.push({ kind: RenderKind.DependencyChange });
      depChangeRef.current = depChanges;
    }
  }, [depChangeRef, renderListRef, renderRef, ...deps]); // eslint-disable-line

  const incrementRenders = React.useCallback(() => {
    if (renderListRef.current.length < renderRef.current) {
      renderListRef.current.push({ kind: RenderKind.SpuriousRerender });
    }
  }, [renderRef, renderListRef]);

  React.useEffect(() => {
    renderRef.current += 1;
  });

  incrementDepChanges();
  incrementRenders();

  return (
    <div>
      <h3>Debugger for {title}</h3>
      <p>
        <b>Renders:</b> {renderRef.current}
        {"\n"}
        <b>Dependency Changes:</b> {depChangeRef.current}
      </p>
      <div className={styles.renderWrapper}>
        {renderListRef.current.reduceRight((out: JSX.Element[], render, idx) => {
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
