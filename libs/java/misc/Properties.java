package misc;

import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;

public class Properties extends java.util.Properties {

  private static final long serialVersionUID = 1L;

  private String document;

  public Properties(String document) { this.setDocument(document); }

  public void loadFile() throws IOException { this.loadFile(document); }

  public void storeFile() throws IOException { this.storeFile(document); }

  /**
   * Wrapper to make it easier to load from file
   * @param docName
   * @throws IOException
   */
  public void loadFile(String docName) throws IOException {
    FileReader file = new FileReader(docName);
    this.load(file);
    file.close();
  }

  /**
   * Wrapper to make it easier to store to file
   * @param docName
   * @throws IOException
   */
  public void storeFile(String docName) throws IOException {
    FileWriter file = new FileWriter(docName);
    this.store(file, "Bot Properties");
    file.close();
  }

  public String getDocument() { return document; }

  public void setDocument(String document) { this.document = document; }
}
