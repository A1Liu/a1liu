import React from "react";

interface DebugRenderProps {
  title: string;
  deps: any[];
}

export const DebugRender: React.VFC<DebugRenderProps> = ({ title, deps }) => {
  const renders = React.useRef(1);
  const depChanges = React.useRef(0);

  React.useEffect(() => {
    renders.current += 1;
  });

  React.useEffect(() => {
    depChanges.current += 1;
  }, [...deps]); // eslint-disable-line

  return (
    <div>
      <h3>Debugger for {title}</h3>
      <pre>
        Renders: {renders.current}
        {"\n"}
        Dependency Changes: {depChanges.current}
      </pre>
    </div>
  );
};
