import React from "react";

type HookResult<
  Value,
  P extends keyof Value,
  Props extends P[]
> = Props["length"] extends 0 ? Value : Pick<Value, P>;

interface ConstateHook<Value extends object> {
  <P extends keyof Value, Props extends P[]>(...props: Props): HookResult<
    Value,
    P,
    Props
  >;
}

type ConstateResult<Props, Value extends object> = [
  React.FC<Props>,
  ConstateHook<Value>
];

const isDev = process.env.NODE_ENV !== "production";
const NO_PROVIDER = {};

function createContextHook(context: React.Context<any>): any {
  if (!isDev) return () => React.useContext(context);

  const message =
    `The context consumer of ${context.displayName} must be wrapped ` +
    `with its corresponding Provider`;

  return () => {
    const value = React.useContext(context);

    // eslint-disable-next-line no-console
    if (value === NO_PROVIDER) console.warn(message);

    return value;
  };
}

// TODO figure out how to get keys to work with generics
export function createContext<Props, Value extends object>(
  useValue: (props: Props) => Value,
  valKeys: (keyof Value)[]
): ConstateResult<Props, Value> {
  const hookName = `Context(${useValue.name ? useValue.name : "??"})`;

  const selectors = valKeys.map((k: keyof Value) => {
    return (v: Value): any => v[k];
  });

  const contextMap = {} as Record<keyof Value, React.Context<any>>;
  const hookMap = {} as Record<keyof Value, () => any>;

  valKeys.forEach((key, idx) => {
    const context = React.createContext(NO_PROVIDER);
    if (isDev) context.displayName = `${hookName}.context("${key}")`;

    contextMap[key] = context;
    hookMap[key] = createContextHook(context);
  });

  const Provider: React.FC<Props> = ({ children, ...props }) => {
    const value = useValue(props as Props);

    return valKeys.reduce((agg, key) => {
      const Provider = contextMap[key].Provider;
      return <Provider value={value[key]}>{agg}</Provider>;
    }, children as React.ReactElement);
  };

  const useProps = function <P extends keyof Value, Props extends P[]>(
    ...props: Props
  ): HookResult<Value, P, Props> {
    const propKeys = props.length === 0 ? valKeys : props;

    const outputValue: Partial<Value> = {};
    propKeys.forEach((key) => (outputValue[key] = hookMap[key]()));

    return outputValue as HookResult<Value, P, Props>;
  };

  if (isDev) {
    Provider.displayName = `${hookName}.Provider`;
    Object.defineProperty(useProps, "name", {
      value: `${hookName}.useProps`,
      writable: false,
    });
  }

  return [Provider, useProps];
}
