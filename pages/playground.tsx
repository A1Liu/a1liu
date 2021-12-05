import { useAsyncLazy, useAsync } from "components/hooks";
import { DebugRender } from "components/debug";
import { createContext } from "components/constate";
import { timeout, Scroll, Btn } from "components/util";
import css from "components/util.module.css";
import React from "react";

interface DataProps {
  url: string;
}

function useData({ url }: DataProps) {
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

const ShowContextDataInner: React.VFC = () => {
  const data = useDataContext();
  return <DisplayData {...data} />;
};

const ShowContextDataTest: React.VFC = () => {
  const { ignored } = useDataContext("ignored");
  return <DebugRender title={"Context Data"} deps={[ignored]} />;
};

const ShowData: React.VFC = () => {
  const data = useData({ url: DATA_URL });

  return (
    <div className={css.col}>
      <DisplayData {...data} />
      <DebugRender title={"Data"} deps={[data.ignored]} />
    </div>
  );
};

const DisplayData: React.VFC<ReturnType<typeof useData>> = (props) => {
  return (
    <div>
      <h2>{props.isLoading ? "loading" : props.isLoaded ? "done" : "lazy"}</h2>
      <h4>Raw fetch count: {props.fetches}</h4>
      <h4>Refetch Counter: {props.counter}</h4>
      <h4>Ignored Counter: {props.ignored}</h4>
      <Scroll tag={"pre"} height={200}>
        {props.data}
      </Scroll>
      <div className={css.row}>
        <Btn onClick={props.refetch}>Refetch</Btn>
        <Btn onClick={() => props.setCounter((c) => c + 1)}>Refetch + 1</Btn>
        <Btn onClick={() => props.setIgnored((i) => i + 1)}>Ignored + 1</Btn>
      </div>
    </div>
  );
};

const Playground: React.VFC = () => {
  return (
    <div className={css.row} style={{ gap: "32px" }}>
      <ShowData />
      <DataProvider url={DATA_URL}>
        <div className={css.col}>
          <ShowContextDataInner />
          <ShowContextDataTest />
        </div>
      </DataProvider>
    </div>
  );
};

export default Playground;
