import { useCounter } from "components/hooks";
import { DebugRender } from "components/debug";
import { timeout, Scroll, Btn } from "components/util";
import cx from "classnames";
import css from "components/util.module.css";
import React from "react";

const Playground: React.VFC = () => {
  return (
    <div className={cx(css.row, css.padded)} style={{ gap: "32px" }}></div>
  );
};

export default Playground;
