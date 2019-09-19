package comp;
import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;
public class Main {

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

  // ---- Integers ------
  public static List<Integer> arrayToList(int[] array) {
    List<Integer> list = new ArrayList<Integer>();
    for (int item : array)
      list.add(item);
    return list;
  }
  public static int[] getInts(
      int count) { // Gets specified amount of ints from input line
    int[] data = new int[count];
    int counter = 0;
    while (SCANNER.hasNext() && counter < count)
      data[counter++] = SCANNER.nextInt();
    return data;
  }
  public static int[] getIntLine(
      int tokenCount) { // Gets specified amount of ints from next line of input
    int[] data = new int[tokenCount];
    int counter = 0;
    Scanner lineScanner = getLineScanner();
    while (lineScanner.hasNext() && counter < tokenCount)
      data[counter++] = lineScanner.nextInt();
    lineScanner.close();
    return data;
  }

  // ------ Doubles ------
  public static List<Double> arrayToList(double[] array) {
    List<Double> list = new ArrayList<Double>();
    for (double item : array)
      list.add(item);
    return list;
  }
  public static double[] getDoubles(
      int count) { // Gets specified amount of doubles from input line
    double[] data = new double[count];
    int counter = 0;
    while (SCANNER.hasNext() && counter < count)
      data[counter++] = SCANNER.nextDouble();
    return data;
  }
  public static double[] getDoubleLine(
      int tokenCount) { // Gets specified amount of doubles from next line of
                        // input
    double[] data = new double[tokenCount];
    int counter = 0;
    Scanner lineScanner = getLineScanner();
    while (lineScanner.hasNext() && counter < tokenCount)
      data[counter++] = lineScanner.nextDouble();
    lineScanner.close();
    return data;
  }

  // ----- Other --------
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
