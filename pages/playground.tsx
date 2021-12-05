import { useAsyncLazy, useAsync } from "components/hooks";
import { timeout } from "components/util";
import css from "components/Util.module.css";
import React from "react";

function useData(url: string) {
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

const ShowData: React.VFC = () => {
  const {
    fetches,
    counter,
    setCounter,
    ignored,
    setIgnored,
    data,
    isLoading,
    isLoaded,
    refetch,
  } = useData("https://jsonplaceholder.typicode.com/todos/1");

  return (
    <div>
      <h1>{isLoading ? "loading" : isLoaded ? "done" : "lazy"}</h1>
      <h4>Raw fetch count: {fetches}</h4>
      <h4>Refetch Counter: {counter}</h4>
      <h4>Ignored Counter: {ignored}</h4>
      <h4> </h4>
      <pre>{data}</pre>
      <div style={{ display: "flex", gap: "8px" }}>
        <button className={css.muiButton} onClick={refetch}>
          Refetch
        </button>
        <button
          className={css.muiButton}
          onClick={() => setCounter((c) => c + 1)}
        >
          Increment Refetch Counter
        </button>
        <button
          className={css.muiButton}
          onClick={() => setIgnored((i) => i + 1)}
        >
          Increment Ignored Counter
        </button>
      </div>
    </div>
  );
};

const Playground: React.VFC = () => {
  return <ShowData />;
};

export default Playground;
