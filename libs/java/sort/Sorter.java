package sort;

import java.util.List;
// import static debug.Debug.*;

/**
 *
 * General Sorter for any object type that implements the Comparable Interface
 *
 * @author Albert Liu
 *
 */
public abstract class Sorter {

  private Accessor<?> accessor;

  /**
   * Sorts a list of values
   * @param list list of values
   * @return the sorted list
   */
  public <T extends Comparable<T>> List<T> sort(List<T> list) {
    return sort(list, 0, list.size());
  }

  /**
   * Sorts a list of values
   * @param list list of values
   * @param startIndex Start index of the sort. Sorts all elements with indices
   *     greater than or equal to startIndex
   * @param endIndex End index of the sort. Sorts all elements with indices less
   *     than endIndex
   * @return the sorted list
   */
  @SuppressWarnings("unchecked")
  public <T extends Comparable<T>> List<T> sort(List<T> list, int startIndex,
                                                int endIndex) {
    accessor = new ListAccessor<T>(list);
    return (List<T>)sort0(accessor, startIndex, endIndex).getData();
  }

  /**
   * Sorts an array of values
   * @param array array of values
   * @return the sorted array
   */
  public <T extends Comparable<T>> T[] sort(T[] array) {
    return sort(array, 0, array.length);
  }

  /**
   * Sorts an array of values
   * @param array array of values
   * @param startIndex Start index of the sort. Sorts all elements with indices
   *     greater than or equal to startIndex
   * @param endIndex End index of the sort. Sorts all elements with indices less
   *     than endIndex
   * @return the sorted array
   */
  @SuppressWarnings("unchecked")
  public <T extends Comparable<T>> T[] sort(T[] array, int startIndex,
                                            int endIndex) {
    accessor = new ArrayAccessor<T>(array);
    return (T[])sort0(accessor, startIndex, endIndex).getData();
  }

  /**
   * Sort method to override
   * @param accessor Accessor object that handles dataType of container for data
   *     being sorted.
   * @param startIndex Start index for sort. Sorts all elements with indices
   *     greater than or equal to startIndex
   * @param endIndex End index of the sort. Sorts all elements with indices less
   *     than endIndex
   * @return the sorted data
   */
  protected abstract <T extends Comparable<T>> Accessor<T>
  sort0(Accessor<T> accessor, int startIndex, int endIndex);

  /**
   * Insertion sort for lists
   * @param list list to sort
   * @param startIndex Start index for sort. Sorts all elements with indices
   *     greater than or equal to startIndex
   * @param endIndex End index of the sort. Sorts all elements with indices less
   *     than endIndex
   * @return the sorted list
   */
  @SuppressWarnings("unchecked")
  public <T extends Comparable<T>> List<T>
  insertionSort(List<T> list, int startIndex, int endIndex) {
    accessor = new ListAccessor<T>(list);
    return (List<T>)this.insertionSort(accessor, startIndex, endIndex)
        .getData();
  }

  /**
   * Insertion sort for arrays
   * @param array array to sort
   * @param startIndex Start index for sort. Sorts all elements with indices
   *     greater than or equal to startIndex
   * @param endIndex End index of the sort. Sorts all elements with indices less
   *     than endIndex
   * @return the sorted array
   */
  @SuppressWarnings("unchecked")
  public <T extends Comparable<T>> T[] insertionSort(T[] array, int startIndex,
                                                     int endIndex) {
    accessor = new ArrayAccessor<T>(array);
    return (T[])this.insertionSort(accessor, startIndex, endIndex).getData();
  }

  /**
   * Insertion sort implementation
   * @param startIndex Start index for sort. Sorts all elements with indices
   *     greater than or equal to startIndex
   * @param endIndex End index of the sort. Sorts all elements with indices less
   *     than endIndex
   * @return the sorted data
   */
  protected final <E extends Comparable<E>> Accessor<E>
  insertionSort(Accessor<E> accessor, int startIndex, int endIndex) {
    if (startIndex > endIndex - 2) {
      return accessor;
    }
    for (int current = startIndex + 1; current < endIndex; ++current) {
      int currentCheck = current - 1;
      E element = accessor.get(current);
      while (currentCheck >= startIndex) {
        if (accessor.compare(currentCheck, element) > 0) {
          accessor.set(accessor.get(currentCheck), currentCheck + 1);
          currentCheck--;
        } else
          break;
      }
      accessor.set(element, currentCheck + 1);
    }
    return accessor;
  }

  public String sortSummary() {
    return String.format("Swaps: %d\nComparisons:%d\nReads: %d\nWrites: %d",
                         accessor.getSwaps(), accessor.getComps(),
                         accessor.getReads(), accessor.getWrites());
  }

  public Accessor<?> getAccessor() { return accessor; }

  //		protected Accessor<E> insertionSort(int startIndex, int endIndex)
  //{ 			for (int current=startIndex+1; current<endIndex; ++current) { 	            int
  //currentCheck = current-1; 	            while (currentCheck>=startIndex &&
  //compare(currentCheck,currentCheck+1) > 0) {
  //	            	swap(currentCheck+1,currentCheck--);
  //	            }
  //	        }
  //			return this;
  //		}
}
