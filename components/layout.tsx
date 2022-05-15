import styles from "./layout.module.css";
import Link from "next/link";
import css from "./util.module.css";
import cx from "classnames";
import React from "react";

const TopNav: React.VFC = () => {
  return (
    <div className={styles.topNav}>
      <div className={styles.navContent}>
        <Link href="/">
          <a className={styles.logo}>Albert Liu</a>
        </Link>

        <nav>
          <Link href="/">
            <a className={styles.navItem}>Home</a>
          </Link>
        </nav>
      </div>
    </div>
  );
};

const Layout: React.FC = (props) => {
  return (
    <div className={styles.fullscreen}>
      <TopNav />
      <div className={styles.main}>{props.children}</div>
    </div>
  );
};

export default Layout;
