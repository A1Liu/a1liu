import type { NextApiRequest, NextApiResponse } from "next";
import fs from "fs";
import path from "path";

const readdir = fs.promises.readdir;
const resolve = path.resolve;

async function getFiles(dir: string): Promise<string[]> {
  const dirents: fs.Dirent[] = await readdir(dir, { withFileTypes: true });
  const files = await Promise.all(
    dirents.map((dirent): Promise<string[]> | string[] => {
      const res = resolve(dir, dirent.name);
      return dirent.isDirectory() ? getFiles(res) : [res];
    })
  );

  return files.flat();
}

const handler = async (req: NextApiRequest, res: NextApiResponse) => {
  const text = `${req.query.text}`;

  const index = text.indexOf("/");

  const dir = resolve("./public/cards", text.substring(0, index));

  const allFiles = await getFiles(dir);
  const relativeFiles = allFiles.map((f) => f.substring(dir.length + 1, f.length - 3));
  const relevantFiles = relativeFiles.filter((file) => {
    // TODO fuzzy matching ig
    return file.startsWith(text);
  });

  const files = relevantFiles;

  res.status(200).json(files);
};

export default handler;
