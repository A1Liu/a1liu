export const timeout = (ms: number): Promise<void> =>
  new Promise((res) => setTimeout(res, ms));

const timeVals = [
  { div: 1000, s: "ms", precision: 1 },
  { div: 60, s: "s", precision: 0 },
  { div: 60, s: "m", precision: 0 },
  { div: 24, s: "h", precision: 0 },
  { div: Infinity, s: "d", precision: 0 },
];

export const fmtTime = (msTime: number): string => {
  let output = "";

  for (const val of timeVals) {
    output = (msTime % val.div).toFixed(val.precision) + val.s + output;

    if (msTime < val.div) break;

    output = " " + output;

    msTime = Math.floor(msTime / val.div);
  }

  return output;
};

export async function defer<T>(cb: () => T): Promise<T> {
  await timeout(0);
  return cb();
}

interface IssueLinkOptions {
  title: string;
  body?: string;
}

const defaultIssueOptions = {
  body: "",
};

export function githubIssueLink(options: IssueLinkOptions): string {
  let urlString = "https://github.com/A1Liu/a1liu/issues/new";

  const query = { ...defaultIssueOptions, ...options };
  const queryString = new URLSearchParams(query).toString();
  if (queryString) {
    urlString += "?" + queryString;
  }

  return urlString;
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
    return (event) => this.push(event.data);
  }

  push(t: T): void {
    this.messages.push(t);

    if (this.resolve) {
      this.resolve(this.messages.splice(0, this.messages.length));
      this.resolve = undefined;
    }
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
