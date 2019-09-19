package commands.simple;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;

class Util {

  private Util() {}

  public static <T> T[] append(T[] array, T newElement) {
    array = Arrays.copyOf(array, array.length + 1);
    array[array.length - 1] = newElement;
    return array;
  }

  public static boolean isNumber(String in) {
    try {
      Integer.parseInt(in);
    } catch (NumberFormatException e) {
      return false;
    }
    return true;
  }

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
