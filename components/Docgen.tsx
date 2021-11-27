import styles from "./docgen/Default.module.css";
import css from "./docgen/Base.module.css";
import cx from "classnames";
import React from "react";

const DocgenLayout: React.FC = (props) => {
  return (
    <>
      <div className={styles.navBar}>
        <button>Hello</button>
      </div>
      <main className={styles.wrapper}>{props.children}</main>
    </>
  );
};

export default DocgenLayout;
