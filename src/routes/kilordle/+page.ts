import type { PageLoad } from "./$types";
import {fetchAsset}  from "@lib/ts/wasm";

export const load = async ({ fetch, params }) => {
  const res = await fetch(`/api/items/${params.id}`);
  const data = fetchAsset("/kilordle/data.rtf");
  const item = await res.json();

  return { item };
};
