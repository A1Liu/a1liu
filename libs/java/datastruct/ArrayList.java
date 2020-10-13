import java.util.Arrays;
import java.util.stream.Collectors;
class ArrayList {

  static float growthFactor = 1.2f;

  public static int[] newArrayList(int capacity) {
    if (capacity < 0) {
      throw new IllegalArgumentException("can't have negative capacity");
    }
    return new int[capacity + 1];
  }

  public static void set(int[] arrayList, int index, int value) {
    if (index < arrayList[0])
      arrayList[index + 1] = value;
    else
      throw new IndexOutOfBoundsException();
  }

  public static int get(int[] arrayList, int index) {
    if (index < arrayList[0])
      return arrayList[index + 1];
    throw new IndexOutOfBoundsException();
  }

  public static int[] add(int[] arrayList, int value) {
    int length = arrayList[0];
    int capacity = arrayList.length - 1;
    if (length == capacity) {
      int[] old = arrayList;
      arrayList = new int[(int)(capacity * growthFactor) + 2];
      for (int i = 0; i <= length; i++) {
        arrayList[i] = old[i];
      }
    }

    arrayList[0]++;
    arrayList[length + 1] = value;
    return arrayList;
  }

  public static String arrayListToString(int[] arrayList) {
    int length = arrayList[0];
    return '[' +
        String.join(" ", Arrays.stream(arrayList)
                             .skip(1)
                             .limit(length)
                             .mapToObj(Integer::toString)
                             .collect(Collectors.toList())) +
        ']';
  }

  public static int removeLast(int[] arrayList) {
    return arrayList[arrayList[0]--];
  }
}

class Main {
  public static void main(String[] args) {
    int[] arrayList = ArrayList.newArrayList(0);

    try {
      ArrayList.get(arrayList, 12);
      throw new RuntimeException("this should have failed");
    } catch (IndexOutOfBoundsException e) {
      System.out.println(e);
    }

    arrayList = ArrayList.add(arrayList, 1);
    arrayList = ArrayList.add(arrayList, 2);
    arrayList = ArrayList.add(arrayList, 3);
    arrayList = ArrayList.add(arrayList, 10);
    ArrayList.set(arrayList, 0, 3);
    System.out.println(ArrayList.arrayListToString(arrayList));
    System.out.println(ArrayList.removeLast(arrayList));
    System.out.println(ArrayList.arrayListToString(arrayList));

    throw new RuntimeException();
  }
}
