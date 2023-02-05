import type { PageLoad } from "./$types";
import { fetchAsset } from "@lib/ts/wasm";

export const load: PageLoad = async ({ fetch, params }) => {
  const data = fetchAsset("/kilordle/data.rtf");

  return { data };
};
