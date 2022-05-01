import styles from "./default.module.css";
import latexStyles from "./latex.module.css";
import css from "./base.module.css";
import cx from "classnames";
import React from "react";

export const DocgenNav: React.VFC = () => {
  return (
    <div className={css.navBar}>
      <button className={css.muiButton}>Hello</button>
    </div>
  );
};

export const Docgen: React.FC = (props) => {
  return (
    <>
      <DocgenNav />
      <main className={styles.wrapper}>{props.children}</main>
    </>
  );
};


export const Latex: React.FC = (props) => {
  return (
    <>
      <DocgenNav />
      <main className={latexStyles.wrapper}>{props.children}</main>
    </>
  );
};
