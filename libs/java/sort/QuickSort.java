package sort;

public class QuickSort extends Sorter {

  @Override
  protected <T extends Comparable<T>> Accessor<T>
  sort0(Accessor<T> accessor, int startIndex, int endIndex) {
    if (endIndex - startIndex < 32) // Base Case
      return this.insertionSort(accessor, startIndex, endIndex);

    T pivot = accessor.get(endIndex - 1); // Partition
    int back = startIndex;
    int front = startIndex;
    int compare;
    for (int current = startIndex; current < endIndex; current++) {
      compare = accessor.compare(current, pivot);
      if (compare < 0) {
        if (back == front)
          accessor.swap(current, back);
        else {
          accessor.swap(current, front);
          accessor.swap(front, back);
        }
        back++;
        front++;
      } else if (compare == 0) {
        accessor.swap(current, front);
        front++;
      }
    }
    sort0(accessor, startIndex, back);
    return sort0(accessor, front, endIndex);
  }
}
