package sort;

public class SortingTest {

  public static <T extends Comparable<T>> void test(Sorter sorter, int n) {
    Integer[] data = sorter.sort(randData(n, 50, 100));
    System.out.println(sorter.sortSummary());
    System.out.printf("Successful?: %s", isSorted(data) ? "yes" : "no");
  }

  public static <T extends Comparable<T>> boolean isSorted(T[] array) {
    for (int i = 1; i < array.length; i++) {
      if (array[i].compareTo(array[i - 1]) < 0)
        return false;
    }
    return true;
  }

  public static Integer[] randData(int length, int avg, int std) {
    Integer[] array = new Integer[length];
    for (int i = 0; i < length; i++) {
      array[i] = (int)(std * (Math.random() - .5)) + avg;
    }
    return array;
  }

  public static OrderInt[] randDataOrder(int length, int avg, int std) {
    OrderInt[] array = new OrderInt[length];
    for (int i = 0; i < length; i++) {
      array[i] = new OrderInt((int)(std * (Math.random() - .5)) + avg, i);
    }
    return array;
  }
  public static class OrderInt implements Comparable<OrderInt> {

    private Integer value;
    private int order;

    public OrderInt(int value, int order) {
      this.value = value;
      this.order = order;
    }

    @Override
    public int compareTo(OrderInt o) {
      return this.getValue().compareTo(o.getValue());
    }

    public int getOrder() { return order; }

    public Integer getValue() { return value; }

    public String toString() { return this.value + "." + this.order; }
  }
}
