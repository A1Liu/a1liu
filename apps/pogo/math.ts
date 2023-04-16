export const HOUR_MS = 60 * 60 * 1000;
export const DAY_MS = 24 * HOUR_MS;

// a+t(b−a)
export function lerp(a: number, b: number, t: number) {
  return a + t * (b - a);
}

// Array of length N with elements  0, 1, 2, ... N - 2, N - 1
export function arrayOfN(n: number): number[] {
  return [...Array.from(Array(n)).keys()];
}

// Creates a dateString
export function dateString(d: Date): string {
  const month = String(d.getMonth()).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  const name = `${d.getFullYear()}0${month}0${day}`;

  return name;
}

export function uuid(s: string = ""): string {
  return `${s}-${Math.random()}-${Math.random()}`;
}
