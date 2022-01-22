import { useAsyncLazy, useAsync, useCounter } from "components/hooks";
import { DebugRender } from "components/debug";
import { createContext } from "components/constate";
import { post, get, Scroll, Btn } from "components/util";
import { useRouter } from "next/router";
import cx from "classnames";
import css from "components/util.module.css";
import styles from "./card-cutter.module.css";
import React from "react";

// 1. Needs to be inline with the bookmark so that e.g. Twitter content blocking
//    won't block it
// 2. The void means the browser won't change the content of the page to the value
//    of the bookmark
const bookmarkValue = `javascript:void (function() {
  var text = "";
  var activeEl = document.activeElement;
  var activeElTagName = activeEl ? activeEl.tagName.toLowerCase() : null;
  if (
    activeElTagName == "textarea" ||
    (activeElTagName == "input" &&
      /^(?:text|search|password|tel|url)$/i.test(activeEl.type) &&
      typeof activeEl.selectionStart == "number")
  ) {
    text = activeEl.value.slice(activeEl.selectionStart, activeEl.selectionEnd);
  } else if (window.getSelection) {
    text = window.getSelection().toString();
  }

  text = encodeURIComponent(text);
  var url = window.location;
  var title = document.title;

  window.open("http://localhost:1337/card-cutter?text="+text+"&url="+url+"&title="+title);
})();`;

const Cutter: React.VFC = () => {
  const router = useRouter();

  const [title, setTitle] = React.useState("");
  const [url, setUrl] = React.useState("");
  const [text, setText] = React.useState("");
  const [file, setFile] = React.useState("");

  const [showSuggestions, setShowSuggestions] = React.useState(false);
  const { data: suggestionsData, isLoaded } = useAsync(
    () => get("http://localhost:1337/api/suggest-card-files", { text: file }),
    [file]
  );

  const suggestions = suggestionsData ?? [];

  React.useEffect(() => {
    // Using this pattern here to get out of the whole "multiple values for a
    // query parameter" thing
    setTitle(`${router.query.title ?? ""}`);
    setText(`${router.query.text ?? ""}`);
    console.log(router.query.text);

    const urlString = `${router.query.url ?? ""}`;
    if (urlString) {
      const url = new URL(urlString);

      const params = url.searchParams;
      params.delete("fbclid");

      url.search = params.toString();
      setUrl(url.toString());
    }
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
            onChange={(evt) => setFile(evt.target.value)}
          />

          <div
            className={cx(
              styles.suggestions,
              showSuggestions && styles.suggestionsVisible
            )}
          >
            {suggestions.map((suggest: string) => (
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
            const body = { title, url, text, file };
            await post("/api/card-cutter", body);

            window.close();

            setTitle("");
            setUrl("");
            setText("");
            setFile("");
          }}
        >
          Cut
        </button>
      </div>

      <div className={cx(css.col, styles.cardArea)}>
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
          className={cx(styles.inputBox, styles.cardContent)}
          value={text}
          onChange={(evt) => setText(evt?.target?.value)}
        />

        {!router.query.url && (
          <div className={styles.inputRow}>
            <label className={styles.suffixLabel}>
              Add the Card Cutter bookmark to start cutting cards!
            </label>

            <button
              className={cx(css.muiButton, styles.fitContent)}
              onClick={(evt) => navigator.clipboard.writeText(bookmarkValue)}
            >
              Copy to clipboard
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default Cutter;
