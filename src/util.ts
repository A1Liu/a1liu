import React from 'react';

export const timeout = (ms: number): Promise<void> =>
  new Promise((res) => setTimeout(res, ms));

export async function defer<T>(cb: () => T): Promise<T> {
  await timeout(0);
  return cb();
}

export async function post(url: string, data: any): Promise<any> {
  const resp = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(data),
  });

  return resp.json();
}

export async function get(urlString: string, query: any): Promise<any> {
  const queryString = new URLSearchParams(query).toString();
  if (queryString) {
    urlString += '?' + queryString;
  }

  const resp = await fetch(urlString);

  return resp.json();
}
