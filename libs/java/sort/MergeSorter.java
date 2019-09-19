package sort;

/**
 * https://github.com/BonzaiThePenguin/WikiSort/blob/master/Chapter%204.%20Faster!.md
 *
 * O(nlogn)
 * O(n)
 * O(logn)
 *
 * Implementation of Bottom-up Merge Sort
 *
 * Similar to wiki-sort but uses simpler method during the combine step
 *
 *
 * @author Albert Liu
 *
 */
public class MergeSorter extends Sorter {

  @Override
  protected <T extends Comparable<T>> Accessor<T>
  sort0(Accessor<T> accessor, int startIndex, int endIndex) {
    // TODO Auto-generated method stub
    /*
     * If endIndex - startIndex < 16, use insertion sort
     *
     * else, recursively sort first half of range and second half of range
     *
     * Then, combine them using the following steps:
     *
     * Let A be the left range and B be the right range. First, find the first
     * element in A that is > B_1. Then swap the B_1 with that element. Then for
     * every other element, swap with the correct element in A or B (favoring
     * A). Each time an element from a range is swapped, the next element is
     * selected by increasing the index for that range by 1. If the A index
     * equals the B index, then the A index is set to the current swap position
     *
     *
     *
     *
     */

    if (endIndex - startIndex < 16) {
      return this.insertionSort(accessor, startIndex, endIndex);
    }

    sort0(accessor, startIndex, endIndex / 2);
    sort0(accessor, endIndex / 2, endIndex);

    return accessor;
  }
}
