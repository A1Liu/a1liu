import styles from "./Latex.module.css";
import css from "./Util.module.css";
import cx from 'classnames';
import React from "react";

const LatexLayout: React.FC = (props) => {
  return <main className={styles.wrapper}>{props.children}</main>;
};

export default LatexLayout;
