import { useAsyncLazy, useAsync } from "components/hooks";
import { DebugRender } from 'components/debug';
import { createContext } from "components/constate";
import { timeout } from "components/util";
import css from "components/util.module.css";
import React from "react";

function useBoi(): { a: string|undefined } {
  const b = {a: "", b: 12};
  return b;
}

const [BoiProvider, useBoiCtx] = createContext(useBoi);

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

const [DataProvider, useDataContext] = createContext(useData);

const ShowContextData: React.VFC = () => {
  return (
    <DataProvider url={DATA_URL}>
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          flexWrap: "nowrap",
          gap: "16px",
        }}
      >
        <ShowContextDataInner />
        <ShowContextDataTest />
      </div>
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
      <DebugRender title={"Context Data"} deps={[ignored]} />
      <h3>Ignored is: {ignored}</h3>
    </div>
  );
};

const ShowData: React.VFC = () => {
  const data = useData({ url: DATA_URL });

  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        flexWrap: "nowrap",
        gap: "16px",
      }}
    >
      <DisplayData {...data} />
      <div>
        <DebugRender title={"Data"} deps={[data.ignored]} />
        <h3>Ignored is: {data.ignored}</h3>
      </div>
    </div>
  );
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
