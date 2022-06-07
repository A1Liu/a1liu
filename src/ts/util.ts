export const timeout = (ms: number): Promise<void> =>
  new Promise((res) => setTimeout(res, ms));

export async function defer<T>(cb: () => T): Promise<T> {
  await timeout(0);
  return cb();
}

export async function post(url: string, data: any): Promise<any> {
  const resp = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(data),
  });

  return resp.json();
}

export async function get(urlString: string, query: any): Promise<any> {
  const queryString = new URLSearchParams(query).toString();
  if (queryString) {
    urlString += "?" + queryString;
  }

  const resp = await fetch(urlString);

  return resp.json();
}

export class WorkerCtx<T> {
  private messages: T[] = [];
  private resolve?: (t: T) => void;

  onmessageCallback(): (event: MessageEvent<T>) => void {
    return (event) => {
      this.messages.push(event.data);

      if (this.resolve) {
        this.resolve(this.messages.splice(0, this.messages.length));
        this.resolve = undefined;
      }
    };
  }

  async msgWait(): Promise<T[]> {
    const p: Promise<T[]> = new Promise((r) => {
      if (this.messages.length > 0) {
        return r(this.messages.splice(0, this.messages.length));
      }

      this.resolve = r;
    });

    return p;
  }
}
