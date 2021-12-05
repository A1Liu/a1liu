import { useAsyncLazy, useAsync } from "components/hooks";
import { keys } from "ts-transformer-keys";
import { createContext } from "components/constate";
import { timeout } from "components/util";
import css from "components/Util.module.css";
import React from "react";

function useData({ url }: { url: string }) {
  const [counter, setCounter] = React.useState(0);
  const [ignored, setIgnored] = React.useState(0);
  const [fetches, setFetches] = React.useState(0);
  const { data, isLoaded, refetch, isLoading } = useAsync(async () => {
    setFetches((f) => ++f);
    await timeout(250);
    return fetch(url).then((r) => r.text());
  }, [counter]);

  return {
    fetches,
    counter,
    setCounter,
    ignored,
    setIgnored,
    data,
    isLoading,
    isLoaded,
    refetch,
  };
}

const DATA_URL = "https://jsonplaceholder.typicode.com/todos/1";
const dataKeys = keys<ReturnType<typeof useData>>();

const [DataProvider, useDataContext] = createContext(useData, dataKeys);

interface DebugRenderProps {
  title: string;
  deps: any[];
}
const DebugRender: React.VFC<DebugRenderProps> = ({ title, deps }) => {
  const renders = React.useRef(1);
  const depChanges = React.useRef(0);

  React.useEffect(() => {
    renders.current += 1;
  });

  React.useEffect(() => {
    depChanges.current += 1;
  }, deps);

  return (
    <div>
      <h3>Debugger for {title}</h3>
      <pre>
        Renders: {renders.current}{'\n'}
        Dependency Changes: {depChanges.current}
      </pre>
    </div>
  );
};

const ShowContextData: React.VFC = () => {
  return (
    <DataProvider url={DATA_URL}>
      <ShowContextDataInner />
      <ShowContextDataTest />
    </DataProvider>
  );
};

const ShowContextDataInner: React.VFC = () => {
  const data = useDataContext();

  return <DisplayData {...data} />;
};

const ShowContextDataTest: React.VFC = () => {
  const { ignored } = useDataContext("ignored");

  return (
    <div>
      <DebugRender title={"Context Data Test"} deps={[ignored]} />
      <h3>Ignored is: {ignored}</h3>
    </div>
  );
};

const ShowData: React.VFC = () => {
  const data = useData({ url: DATA_URL });

  return <DisplayData {...data} />;
};

const DisplayData: React.VFC<ReturnType<typeof useData>> = ({
  fetches,
  counter,
  setCounter,
  ignored,
  setIgnored,
  data,
  isLoading,
  isLoaded,
  refetch,
}) => {
  return (
    <div>
      <h2>{isLoading ? "loading" : isLoaded ? "done" : "lazy"}</h2>
      <h4>Raw fetch count: {fetches}</h4>
      <h4>Refetch Counter: {counter}</h4>
      <h4>Ignored Counter: {ignored}</h4>
      <pre>{data}</pre>
      <div style={{ display: "flex", gap: "8px" }}>
        <button className={css.muiButton} onClick={refetch}>
          Refetch
        </button>
        <button
          className={css.muiButton}
          onClick={() => setCounter((c) => c + 1)}
        >
          Refetch + 1
        </button>
        <button
          className={css.muiButton}
          onClick={() => setIgnored((i) => i + 1)}
        >
          Ignored + 1
        </button>
      </div>
    </div>
  );
};

const Playground: React.VFC = () => {
  return (
    <div style={{ display: "flex", flexDirection: "row", gap: "32px" }}>
      <ShowData />
      <ShowContextData />
    </div>
  );
};

export default Playground;
