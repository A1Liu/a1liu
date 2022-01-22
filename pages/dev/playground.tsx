import { useAsyncLazy, useAsync, useCounter } from "components/hooks";
import { DebugRender } from "components/debug";
import { createContext } from "components/constate";
import { timeout, Scroll, Btn } from "components/util";
import cx from "classnames";
import css from "components/util.module.css";
import React from "react";

interface DataProps {
  url: string;
}

function useData({ url }: DataProps) {
  const [counter, incrCounter] = useCounter(0);
  const [ignored, incrIgnored] = useCounter(0);
  const [fetches, incrFetches] = useCounter(0);
  const { data, isLoaded, refetch, isLoading } = useAsync(async () => {
    incrFetches();
    await timeout(250);
    return fetch(url).then((r) => r.text());
  }, [url, counter, incrFetches]); // eslint-disable-line

  const title = isLoading ? "loading" : isLoaded ? "done" : "lazy";

  return {
    fetches,
    counter,
    incrCounter,
    ignored,
    incrIgnored,
    data,
    title,
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
      <h2>{props.title}</h2>
      <h4>Raw fetch count: {props.fetches}</h4>
      <h4>Refetch Counter: {props.counter}</h4>
      <h4>Ignored Counter: {props.ignored}</h4>
      <Scroll tag={"pre"} height={200}>
        {props.data}
      </Scroll>
      <div className={css.row}>
        <Btn onClick={props.refetch}>Refetch</Btn>
        <Btn onClick={() => props.incrCounter()}>Refetch + 1</Btn>
        <Btn onClick={() => props.incrIgnored()}>Ignored + 1</Btn>
      </div>
    </div>
  );
};

const Playground: React.VFC = () => {
  return (
    <div className={cx(css.row, css.padded)} style={{ gap: "32px" }}>
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
