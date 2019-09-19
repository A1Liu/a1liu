package io;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;

public class ReadFile {

  private ReadFile() {}

  // Example path string
  String directory = "C:\\Users\\Alyer\\";

  public static String readTextFile(String fileName) throws IOException {
    return new String(Files.readAllBytes(Paths.get(fileName)));
  }

  /**
   * Reads the file that is given and creates a list from it
   * @param input name of file to be read
   * @throws IOException Throws an exception if there's a problem reading the
   *     file
   */
  public static ArrayList<String> readFile(String input) throws IOException {

    BufferedReader reader = new BufferedReader(new FileReader(input));
    ArrayList<String> output = new ArrayList<String>();

    String inputString = reader.readLine();
    while (inputString != null) {
      output.add(inputString);
      inputString = reader.readLine();
    }
    reader.close();
    return output;
  }

  /**
   * Reads the lines of a document and returns the entire document as a String
   * Array
   * @param document name of document, or path
   * @return text in document as a string array, each element is one line.
   * @throws IOException if something goes wrong with inputs
   */
  public static String[] readLines(String document) throws IOException {
    BufferedReader reader = new BufferedReader(new FileReader(document));
    ArrayList<String> output = new ArrayList<String>();

    String inputString = reader.readLine();
    while (inputString != null) {
      output.add(inputString);
      inputString = reader.readLine();
    }
    reader.close();
    return output.toArray(new String[output.size()]);
  }
}
