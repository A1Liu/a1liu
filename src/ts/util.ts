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

export class WorkerRef<In, Out> {
  private workerRef: Worker | undefined = undefined;
  private readonly messages: { msg: In; deps?: Transferable[] }[] = [];

  onmessage: (ev: MessageEvent<Out>) => void = () => {};

  constructor(private readonly CreatorClass: { new (): Worker }) {}

  get ref(): Worker | undefined {
    return this.workerRef;
  }

  init() {
    const worker = new this.CreatorClass();
    worker.onmessage = (ev: MessageEvent<Out>) => this.onmessage(ev);

    this.workerRef = worker;
    this.messages
      .splice(0, this.messages.length)
      .forEach(({ msg, deps }) => this.postMessage(msg, deps));
  }

  postMessage(msg: In, deps?: Transferable[]) {
    if (!this.workerRef) {
      this.messages.push({ msg, deps });
      return;
    }

    if (deps) this.workerRef.postMessage(msg, deps);
    else this.workerRef.postMessage(msg);
  }
}

export class WorkerCtx<In, Out> {
  private messages: In[] = [];
  private resolve?: (t: In[]) => void;

  constructor(private readonly workerPostMessage: typeof postMessage) {}

  onmessageCallback(): (event: MessageEvent<In>) => void {
    return (event) => this.push(event.data);
  }

  push(t: In): void {
    this.messages.push(t);

    if (this.resolve) {
      this.resolve(this.messages.splice(0, this.messages.length));
      this.resolve = undefined;
    }
  }

  async msgWait(): Promise<In[]> {
    const p: Promise<In[]> = new Promise((r) => {
      if (this.messages.length > 0) {
        return r(this.messages.splice(0, this.messages.length));
      }

      this.resolve = r;
    });

    return p;
  }

  postMessage(message: Out) {
    // The "postMessage" function needs to be called as a bare function,
    // and not as a member function, so e.g. this.workerPostMessage(message);
    // would fail. This was tested on Microsoft Edge.
    const workerPostMessage = this.workerPostMessage;
    workerPostMessage(message);
  }
}
