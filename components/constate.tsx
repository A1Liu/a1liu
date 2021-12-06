import React from "react";
import { useStable } from "components/hooks";

type HookResult<
  Value,
  P extends keyof Value,
  Props extends P[]
> = Props["length"] extends 0 ? Value : Pick<Value, P>;

interface ConstateHook<Value> {
  <P extends keyof Value, Props extends P[]>(...props: Props): HookResult<
    Value,
    P,
    Props
  >;
}

type ConstateResult<Props, Value> = [React.FC<Props>, ConstateHook<Value>];

const isDev = process.env.NODE_ENV !== "production";
const NO_PROVIDER = {};

// Required<Value> is used here to prevent the number of fields detected at runtime
// from changing.
export function createContext<Props, Value>(
  useValue: (props: Props) => Required<Value>
): ConstateResult<Props, Value> {
  const hookName = `Context(${useValue.name ? useValue.name : "??"})`;

  interface Field {
    ctx: React.Context<any>;
    hook: () => any;
  }

  const fieldMap: Partial<Record<keyof Value, Field>> = {};
  const baseCtx = React.createContext<typeof NO_PROVIDER | null>(NO_PROVIDER);
  baseCtx.displayName = hookName;

  const getFieldInfo = (key: keyof Value): Field => {
    const field = fieldMap[key];
    if (field) return field;

    const ctx = React.createContext(undefined);
    if (isDev) ctx.displayName = `${hookName}.context("${key}")`;
    const useCtx = () => React.useContext(ctx);

    return (fieldMap[key] = { ctx, hook: useCtx });
  };

  let propCount: number | null = null;
  const Provider: React.FC<Props> = ({ children, ...props }) => {
    const hookValue = useValue(props as Props);

    const valueEntries = Object.entries(hookValue);
    const element = valueEntries.reduce((agg, [key, value]) => {
      const Provider = getFieldInfo(key as keyof Value).ctx.Provider;

      return <Provider value={value}>{agg}</Provider>;
    }, <baseCtx.Provider value={null}>{children}</baseCtx.Provider>);

    let count = valueEntries.length;
    if (propCount === count) return element;

    if (propCount === null) {
      propCount = count;
      return element;
    }

    const msg = `prop count changed for ${hookName}, which will result in runtime errors`;
    throw new Error(msg);
  };

  const useProps = function <P extends keyof Value, Props extends P[]>(
    ...props: Props
  ): HookResult<Value, P, Props> {
    const base = React.useContext(baseCtx);
    if (base === NO_PROVIDER) {
      throw new Error(
        `The consumer of ${hookName} must be wrapped with its Provider`
      );
    }

    const propKeys =
      props.length === 0 ? (Object.keys(fieldMap) as P[]) : props;
    const partialValue: Partial<Record<keyof Value, any>> = {};
    propKeys.forEach((key) => (partialValue[key] = getFieldInfo(key).hook()));
    const output = useStable(partialValue);

    return output as HookResult<Value, P, Props>;
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
