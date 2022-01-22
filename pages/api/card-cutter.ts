import type { NextApiRequest, NextApiResponse } from "next";
import fs from "fs";
import path from "path";

const { mkdir, appendFile } = fs.promises;
const { resolve } = path;

const handler = async (req: NextApiRequest, res: NextApiResponse) => {
  const { file: inputFilePath, url, title, text } = req.body;
  if (!inputFilePath || !url || !title || !text) {
    return res.status(400).json({ error: "path wasn't valid" });
  }

  const index = inputFilePath.indexOf("/");
  const dir = resolve("./public/cards", inputFilePath.substring(0, index));

  await mkdir(dir, { recursive: true });

  const filePath = resolve("./public/cards", inputFilePath + ".md");

  const content = `Title: ${title}
Source: ${url}

${text}

--------------------------------------------------------------------------------

`;

  await appendFile(filePath, content);


  return res.status(200).json({});
};

export default handler;
