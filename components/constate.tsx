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

// TODO figure out how to get keys to work with generics
export function createContext<Props, Value extends object>(
  useValue: (props: Props) => Value
): ConstateResult<Props, Value> {
  const hookName = `Context(${useValue.name ? useValue.name : "??"})`;

  interface Field {
    ctx: React.Context<any>;
    hook: () => any;
  }

  const fieldMap: Partial<Record<keyof Value, Field>> = {};
  const baseCtx = React.createContext<typeof NO_PROVIDER | null>(NO_PROVIDER);
  baseCtx.displayName = hookName;

  const getFieldInfo = (keyString: number | string | symbol): Field => {
    const key = keyString as keyof Value;
    const field = fieldMap[key];
    if (field) return field;

    const ctx = React.createContext(undefined);
    if (isDev) ctx.displayName = `${hookName}.context("${key}")`;
    const hook = () => React.useContext(ctx);

    return (fieldMap[key] = { ctx, hook });
  };

  const Provider: React.FC<Props> = ({ children, ...props }) => {
    const hookValue = useValue(props as Props);
    const BaseProvider = baseCtx.Provider;

    return Object.entries(hookValue).reduce((agg, [key, value]) => {
      const Provider = getFieldInfo(key).ctx.Provider;
      return <Provider value={value}>{agg}</Provider>;
    }, <BaseProvider value={null}>{children}</BaseProvider>);
  };

  const useProps = function <P extends keyof Value, Props extends P[]>(
    ...props: Props
  ): HookResult<Value, P, Props> {
    const base = React.useContext(baseCtx);
    const propKeys =
      props.length === 0 ? (Object.keys(fieldMap) as P[]) : props;
    const outputValue: Partial<Record<keyof Value, any>> = {};
    propKeys.forEach(
      (key) => (outputValue[key as keyof Value] = getFieldInfo(key).hook())
    );

    if (base === NO_PROVIDER) {
      const message = `The consumer of ${hookName} must be wrapped with its Provider`;
      console.warn(message);
    }

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
