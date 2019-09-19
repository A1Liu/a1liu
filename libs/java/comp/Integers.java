package comp;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedList;
import java.util.List;
import java.util.Scanner;

public class Integers {
  private static final Scanner SCANNER = new Scanner(System.in);

  public static void main(String... strings) {}

  public static void spf(String format, Object... args) {
    System.out.printf(format, args);
  }
  public static Scanner
  getLineScanner() { // Gets a scanner that scans the next line
    return new Scanner(SCANNER.nextLine());
  }

  // --- Output
  public static int getNext() { return SCANNER.nextInt(); }
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
    while (counter < count && SCANNER.hasNext())
      data[counter++] = SCANNER.nextInt();
    return data;
  }
  public static int[] getIntLine(
      int tokenCount) { // Gets specified amount of ints from next line of input
    int[] data = new int[tokenCount];
    int counter = 0;
    Scanner lineScanner = getLineScanner();
    while (counter < tokenCount && lineScanner.hasNext())
      data[counter++] = lineScanner.nextInt();
    lineScanner.close();
    return data;
  }

  public static int getPrimesUntil(int n) { // when n = 0, p = 2.
    int[] primes =
        new int[] {2,  3,  5,  7,  11, 13, 17, 19, 23, 29, 31, 37, 41,
                   43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97};
    if (n < 100)
      return primes[n];
    boolean[] prime = new boolean[n + 1];
    Arrays.fill(prime, true);
    for (int p = 2; p * p <= Math.pow(n, 2); p++)
      if (prime[p])
        for (int i = p * 2; i <= n; i += p)
          prime[i] = false;
    LinkedList<Integer> primeNumbers = new LinkedList<>();
    for (int i = 2; i <= n; i++)
      if (prime[i])
        primeNumbers.add(i);
    return primeNumbers.getLast();
  }
}
