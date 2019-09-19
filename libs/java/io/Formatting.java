package io;

public class Formatting { // TODO Write a thing that formats inputs into data
                          // arrays using a formatting string
  // i.e. format string is %d;%d, then formatter returns 1 and 2 given input
  // string "1;2"
  // basically a generalized parser of text
  // get double, get string, etc.

  private Formatting() {}

  /**
   * checks if a string is an integer
   * @param in string to test
   * @return true if the string can be parsed to an integer
   */
  public static boolean isNumber(String in) {
    try {
      Integer.parseInt(in);
    } catch (NumberFormatException e) {
      return false;
    }
    return true;
  }

  public static boolean isIntList(String list) {

    String[] listElements = list.split("\\s*,\\s*");

    for (int x = 0; x < listElements.length; x++) {
      try {
        Integer.parseInt(listElements[x]);
      } catch (NumberFormatException n) {
        return false;
      }
    }
    return true;
  }
}
