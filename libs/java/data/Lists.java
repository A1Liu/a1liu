package data;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class Lists {

  public static <T> T[] append(T[] array, T newElement) {
    array = Arrays.copyOf(array, array.length + 1);
    array[array.length - 1] = newElement;
    return array;
  }

  public static <T> T[] prepend(T[] array, T newElement) {
    T[] newArray = Arrays.copyOf(array, array.length + 1);
    for (int x = 1; x < newArray.length; x++) {
      newArray[x] = array[x - 1];
    }
    newArray[0] = newElement;
    return newArray;
  }

  /**
   * turns an array to a list
   * @param array array to return
   * @return array as a list
   */
  public static <T> List<T> arrayToList(T[] array) {
    List<T> list = new ArrayList<T>();
    for (T item : array) {
      list.add(item);
    }
    return list;
  }
}
