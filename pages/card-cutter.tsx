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

  const [title, setTitle] = React.useState("");
  const [url, setUrl] = React.useState("");
  const [text, setText] = React.useState("");
  const [file, setFile] = React.useState("");

  const [showSuggestions, setShowSuggestions] = React.useState(false);
  const { data: suggestionsData, isLoaded } = useAsync(async () => {
    const url = new URL("http://localhost:1337/api/suggest-card-files");
    url.search = new URLSearchParams({ text: file }).toString();

    const response = await fetch(url);
    return response.json();
  }, [file]);

  const suggestions = suggestionsData ?? [];

  React.useEffect(() => {
    setTitle(router.query.title);
    setUrl(router.query.url);
    setText(router.query.text);
  }, [router.query]);

  return (
    <div className={cx(css.col, styles.fullscreen)}>
      <div className={styles.inputRow}>
        <div className={styles.inputWrapper}>
          <input
            type="text"
            className={styles.inputBox}
            value={file}
            placeholder={"file to store the card in"}
            onFocus={() => setShowSuggestions(true)}
            onBlur={() => setShowSuggestions(false)}
            onChange={(evt) => setFile(evt?.target?.value)}
          />

          <div
            className={cx(
              styles.suggestions,
              showSuggestions && styles.suggestionsVisible
            )}
          >
            {suggestions.map((suggest) => (
              <button
                key={suggest}
                className={styles.suggestion}
                onMouseDown={() => setFile(suggest)}
              >
                {suggest}
              </button>
            ))}
          </div>
        </div>

        <button
          className={css.muiButton}
          onClick={async () => {
            await fetch("/api/card-cutter", {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
              },
              body: JSON.stringify({ title, url, text, file }),
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
            <div className={styles.inputRow}>
              <label className={styles.cardLabel}>Title</label>
              <input
                type="text"
                className={styles.inputBox}
                value={title}
                onChange={(evt) => setTitle(evt?.target?.value)}
              />
            </div>

            <div className={styles.inputRow}>
              <label className={styles.cardLabel}>Source</label>
              <input
                type="text"
                className={styles.inputBox}
                value={url}
                onChange={(evt) => setUrl(evt?.target?.value)}
              />
            </div>

            <textarea
              type="text"
              className={cx(styles.inputBox, styles.cardContent)}
              value={text}
              onChange={(evt) => setText(evt?.target?.value)}
            />
          </>
        )}
      </div>
    </div>
  );
};

export default Cutter;
