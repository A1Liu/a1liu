import { useAsyncLazy, useAsync } from "../components/hooks";
import { timeout } from "../components/util";
import React from "react";

const ShowData: React.VFC = () => {
  const [counter, setCounter] = React.useState(0);
  const [ignored, setIgnored] = React.useState(0);
  const fetchCounter = React.useRef(0);
  const { data, isLoaded, refetch, isLoading } = useAsync(async () => {
    console.log("Running...");
    await timeout(250);
    return fetch("https://jsonplaceholder.typicode.com/todos/1")
      .then((r) => r.text())
      .then((t) => t + 'f: ' + (fetchCounter.current++) + ' c: ' + counter);
  }, [counter]);

  return (
    <div>
      <h1>{isLoading ? "loading" : isLoaded ? "done" : "lazy"}</h1>
      <pre>{data}</pre>
      <button onClick={refetch}>Refetch</button>
      <button onClick={() => setCounter((c) => c + 1)}>
        Refetch through counter
      </button>
      <button onClick={() => setIgnored((i) => i + 1)}>No refetch</button>
    </div>
  );
};

const Playground: React.VFC = () => {
  return <ShowData />;
};

export default Playground;
