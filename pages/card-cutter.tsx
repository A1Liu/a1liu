import { useAsyncLazy, useAsync, useCounter } from "components/hooks";
import { DebugRender } from "components/debug";
import { createContext } from "components/constate";
import { timeout, Scroll, Btn } from "components/util";
import { useRouter } from "next/router";
import cx from "classnames";
import css from "components/util.module.css";
import styles from "./card-cutter.module.css";
import React from "react";

const bookmarkValue = `javascript:void(function(s){s.src='http://localhost:1337/open-card-cutter.js';document.body.appendChild(s)}(document.createElement('script')))`;

const Cutter: React.VFC = () => {
  const router = useRouter();
  const [file, setFile] = React.useState<string>("");
  const [showSuggestions, setShowSuggestions] = React.useState(false);
  const { data: suggestionsData, isLoaded } = useAsync(async () => {
    const url = new URL("http://localhost:1337/api/suggest-card-files");
    url.search = new URLSearchParams({ text: file }).toString();

    const response = await fetch(url);
    return response.json();
  }, [file]);

  const suggestions = suggestionsData ?? [];

  return (
    <div className={cx(css.col, styles.fullscreen)}>
      <div className={cx(css.row, styles.cutCardRow)}>
        <div>
          <input
            type="text"
            className={styles.inputBox}
            value={file}
            onFocus={() => setShowSuggestions(true)}
            onBlur={() => setShowSuggestions(false)}
            onChange={(evt) => setFile(evt?.target?.value)}
          />

          <div
            className={cx(
              css.col,
              styles.suggestions,
              showSuggestions && styles.suggestionsVisible
            )}
          >
            {suggestions.map((file) => (
              <div key={file} className={styles.suggestion}>
                {file}
              </div>
            ))}
          </div>
        </div>

        <button
          className={css.muiButton}
          onClick={async () => {
            const body = {
              ...router.query,
              file,
            };

            await fetch("/api/card-cutter", {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
              },
              body: JSON.stringify(body),
            });

            window.close();
          }}
        >
          Cut
        </button>
      </div>

      <div className={cx(css.col, styles.cardArea)}>
        {!router.query.url && (
          <>
            <h3>Add the Card Cutter bookmark to start cutting cards!</h3>

            <button
              className={cx(css.muiButton, styles.fitContent)}
              onClick={(evt) => navigator.clipboard.writeText(bookmarkValue)}
            >
              Copy to clipboard
            </button>
          </>
        )}

        {router.query.url && (
          <>
            <h3>Title: {router.query.title}</h3>
            <h3>Source: {router.query.url}</h3>

            <pre className={styles.cardContent}>{router.query.text}</pre>
          </>
        )}
      </div>
    </div>
  );
};

export default Cutter;
