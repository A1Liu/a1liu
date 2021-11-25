import styles from "./Layout.module.css";
import css from './Util.module.css';
import cx from 'classnames';
import React from "react";

const TopNav: React.VFC = () => {
  return (
    <div className={styles.topNav}>
      <div className={styles.navContent}>
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

const Layout: React.FC = props => {
  return (
    <div className={css.fullscreen}>
      <TopNav />
      <div className={styles.main} >
        {props.children}
      </div>
    </div>
  );
};

export default Layout;
