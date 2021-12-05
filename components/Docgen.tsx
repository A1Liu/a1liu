import styles from "./docgen/Default.module.css";
import css from "./docgen/Base.module.css";
import cx from "classnames";
import React from "react";

export const DocgenNav: React.VFC = () => {
  return (
    <div className={css.navBar}>
      <button className={css.muiButton}>Hello</button>
    </div>
  );
};

const DocgenLayout: React.FC = (props) => {
  return (
    <>
      <DocgenNav />
      <main className={styles.wrapper}>{props.children}</main>
    </>
  );
};

export default DocgenLayout;
