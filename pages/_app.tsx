import "./global.css";
import Head from "next/head";
import type { AppProps } from "next/app";

function MyApp({ Component, pageProps }: AppProps) {
  return (
    <>
      <Head>
        <title key="title">Albert's Site</title>
      </Head>
      <Component {...pageProps} />
    </>
  );
}

export default MyApp;
