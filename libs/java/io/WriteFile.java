package io;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;

public class WriteFile {

  private WriteFile() {}

  public static void writeToTextFile(String fileName, String content)
      throws IOException {
    Files.write(Paths.get(fileName), content.getBytes(),
                StandardOpenOption.CREATE);
  }

  /**
   * writes to a document at the path specified
   * @param outPath path of the document to write to
   * @param strings the strings to write
   * @throws IOException If there's a problem writing to the file
   */
  public static void writeFile(String outPath, String... strings)
      throws IOException {
    BufferedWriter writer = new BufferedWriter(new FileWriter(outPath));
    for (int x = 0; x < strings.length; x++) {
      writer.write(strings[x]);
      writer.newLine();
    }
    writer.close();
  }
}
