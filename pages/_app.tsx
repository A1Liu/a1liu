import "./global.css";
import Head from "next/head";
import { ToastCorner } from "components/errors";
import { post, get } from "components/util";
import type { AppProps } from "next/app";
import { QueryClient, QueryClientProvider } from "react-query";

// https://github.com/timolins/react-hot-toast

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      queryFn: async ({ queryKey }) => {
        if (queryKey.length < 2) {
          throw new Error("wtf");
        }

        const url = queryKey[1] as string;

        if (queryKey[0] === "get") {
          return get(url, queryKey[2] ?? {});
        }

        if (queryKey[0] === "post") {
          return post(url, {});
        }
      },
    },
  },
});

function MyApp({ Component, pageProps }: AppProps) {
  return (
    <>
      <Head>
        <title key="title">Albert&apos;s Site</title>
      </Head>

      <QueryClientProvider client={queryClient}>
        <Component {...pageProps} />
      </QueryClientProvider>

      <ToastCorner></ToastCorner>
    </>
  );
}

export default MyApp;
