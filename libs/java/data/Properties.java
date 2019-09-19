package data;

import java.io.FileInputStream;
import java.io.IOException;

public class Properties {

  /**
   * gets a specified property from a specified property file.
   * @param documentName Name of property file
   * @param propName Name of property
   * @return value of property category
   * @throws IOException if there's a problem with retrieving or parsing the
   *     file.
   */
  public static String getProperty(String documentName, String propName)
      throws IOException {
    String rootPath = Thread.currentThread()
                          .getContextClassLoader()
                          .getResource("")
                          .getPath();
    String docPath = rootPath + documentName;
    java.util.Properties docProps = new java.util.Properties();
    docProps.load(new FileInputStream(docPath));
    String prop = docProps.getProperty(propName);
    if (prop == null || prop.trim().length() == 0) {
      prop = null;
    }
    return prop;
  }
}
