package comp;

import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

public class Characters {
  private static final Scanner SCANNER = new Scanner(System.in);

  public static void main(String... strings) {}

  public static void sp() { System.out.println(); }
  public static void sp(Object o) {
    if (o == null)
      System.out.println("null");
    else
      System.out.println(o.toString());
  }
  public static void spf(String format, Object... args) {
    System.out.printf(format, args);
  }
  public static Scanner
  getLineScanner() { // Gets a scanner that scans the next line
    return new Scanner(SCANNER.nextLine());
  }

  // ----- Other --------
  public static String getNext() { return SCANNER.next(); }
  public static <T> List<T> arrayToList(T[] array) {
    List<T> list = new ArrayList<T>();
    for (T item : array)
      list.add(item);
    return list;
  }
  public static List<Character> arrayToList(char[] array) {
    List<Character> list = new ArrayList<Character>();
    for (char item : array)
      list.add(item);
    return list;
  }
  public static List<Long> arrayToList(long[] array) {
    List<Long> list = new ArrayList<Long>();
    for (long item : array)
      list.add(item);
    return list;
  }
  public static List<Boolean> arrayToList(boolean[] array) {
    List<Boolean> list = new ArrayList<Boolean>();
    for (boolean item : array)
      list.add(item);
    return list;
  }
}
