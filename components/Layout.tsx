import styles from "./Layout.module.css";
import cx from 'classnames';
import React from "react";

const TopNav: React.FC = () => {
  return (
    <div className={styles.topNav}>
      <div className={styles.col8}>
        <a className={styles.logo} href={"/"}>
          Albert Liu
        </a>

        <nav>
          <a href={"/"} className={styles.navItem}>
            Home
          </a>
          <a href="/blog" className={styles.navItem}>
            Blog
          </a>
          <a href="/career" className={styles.navItem}>
            CV
          </a>
          <a href="/resources" className={styles.navItem}>
            Resources
          </a>
        </nav>
      </div>
    </div>
  );
};

export default (props) => {
  return (
    <div className={styles.fullscreen}>
      <TopNav />
    </div>
  );
};
