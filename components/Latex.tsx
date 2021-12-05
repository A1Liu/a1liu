import { DocgenNav } from "./Docgen";
import styles from "./docgen/Latex.module.css";
import css from "./docgen/Base.module.css";
import cx from "classnames";
import React from "react";

const LatexLayout: React.FC = (props) => {
  return (
    <>
      <DocgenNav />
      <main className={styles.wrapper}>{props.children}</main>
    </>
  );
};

export default LatexLayout;
