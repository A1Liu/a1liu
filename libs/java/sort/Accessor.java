package sort;

import java.util.List;

/**
 *
 * Class that handles data access. Has methods for getting, setting, swapping,
 * and comparing elements. Also implements a version of insertion sort.
 *
 * @author Albert Liu
 *
 * @param <E>
 */
abstract class Accessor<E extends Comparable<E>> { // TODO Make accessor extend
                                                   // List

  protected int swaps;
  protected int comparisons;
  protected int reads;
  protected int writes;

  Accessor() {
    swaps = 0;
    comparisons = 0;
    reads = 0;
    writes = 0;
  }

  /**
   * Getter for the data stored in the accessor
   * @return the data
   */
  protected abstract Object getData();

  /**
   * Getter for element at an index
   * @param index index of the element
   * @return the element at the index
   */
  public abstract E get(int index);

  /**
   * Setter for a location in the data
   * @param element the element to put at the location
   * @param index the index to put the element
   * @return the element that was previously at that location
   */
  public abstract E set(E element, int index);

  /**
   * Swaps two elements in the data
   * @param index1 index of first element to be swapped
   * @param index2 index of second element to be swapped
   */
  public final void swap(int index1, int index2) {
    set(set(get(index2), index1), index2);
    swaps++;
  }

  /**
   * Compares data in 2 indices using get(index1).compareTo(get(index2))
   * @param index1 index of first element
   * @param index2 index of element to compare the first to
   * @return the result of the comparison
   */
  public final int compare(int index1, int index2) {
    int i = get(index1).compareTo(get(index2));
    comparisons++;
    return i;
  }

  /**
   * Compares 2 elements, one of which is an index, the other of which is an
   * element
   * @param index index of element
   * @param element other element to compare to
   * @return the result of compareTo
   */
  public final int compare(int index, E element) {
    int i = get(index).compareTo(element);
    comparisons++;
    return i;
  }

  /**
   * Compares 2 elements, one of which is an index, the other of which is an
   * element
   * @param element element to compare
   * @param index index of other element to compare to
   * @return the result of compareTo
   */
  public final int compare(E element, int index) {
    int i = element.compareTo(get(index));
    comparisons++;
    return i;
  }

  /**
   * Getter for number of swaps
   * @return number of swaps
   */
  public final int getSwaps() { return swaps; }

  /**
   * getter for number of comparisons
   * @return number of comparisons
   */
  public final int getComps() { return comparisons; }

  /**
   * Getter for number of reads
   * @return number of reads
   */
  public final int getReads() { return reads; }

  /**
   * Getter for number of writes
   * @return number of writes
   */
  public final int getWrites() { return writes; }
}

final class ArrayAccessor<T extends Comparable<T>> extends Accessor<T> {

  private T[] array;

  ArrayAccessor(T[] array) { this.array = array; }

  @Override
  public T get(int index) {
    reads++;
    return array[index];
  }

  @Override
  public T set(T element, int index) {
    reads++;
    writes++;
    T temp = array[index];
    array[index] = element;
    return temp;
  }

  @Override
  protected Object getData() {
    return array;
  }
}

final class ListAccessor<T extends Comparable<T>> extends Accessor<T> {

  private List<T> list;

  ListAccessor(List<T> list) { this.list = list; }

  @Override
  public T get(int index) {
    reads++;
    return list.get(index);
  }

  @Override
  public T set(T element, int index) {
    reads++;
    writes++;
    return list.set(index, element);
  }

  @Override
  protected Object getData() {
    return list;
  }
}
