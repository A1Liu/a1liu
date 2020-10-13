// First index denotes size of underlying heap. Queue always is a min-heap, to
// use as a max-heap multiple input/output by negative 1
class PriorityQueueComparator {

  static float growthFactor = 1.2f;

  static int[] newQueue(int initialSize) { return new int[initialSize + 1]; }
  static int sizeOf(int[] queue) { return queue[0]; }

  interface Comparator {
    // returns true if left is less than right
    boolean compare(int l, int r);
  }

  static int pop(int[] queue, Comparator c) {
    int size = queue[0];
    if (queue[0] == 0) {
      throw new RuntimeException("popped from queue of size zero");
    }

    int retValue = queue[1];
    int current = queue[size];
    int currentIdx = 1;
    int leftIdx = currentIdx * 2;
    int rightIdx = leftIdx + 1;

    while (leftIdx <= size) {
      int left = queue[leftIdx];
      boolean changed = false;
      int idx = -1;
      int val = -1;

      if (c.compare(left, current)) {
        changed = true;
        idx = leftIdx;
        val = left;
      }

      if (rightIdx < size) {
        int right = queue[rightIdx];
        if (c.compare(right, current) && c.compare(right, left)) {
          changed = true;
          idx = rightIdx;
          val = right;
        }
      }

      if (!changed) {
        break;
      }

      queue[currentIdx] = val;
      currentIdx = idx;
      leftIdx = currentIdx * 2;
      rightIdx = leftIdx + 1;
    }

    queue[currentIdx] = current;
    size -= 1;
    queue[0] = size;
    return retValue;
  }

  static int[] push(int[] queue, int value, Comparator c) {
    int size = queue[0];

    // If we need to resize
    if (size >= queue.length - 1) {
      int[] queue2 = new int[(int)(size * growthFactor) + 2];
      for (int i = 0; i <= size; i++) {
        queue2[i] = queue[i];
      }
      queue = queue2;
    }

    size += 1;
    queue[0] = size;

    int currentIdx = size;
    int parentIdx = size / 2;
    int parent = queue[parentIdx];
    while (parentIdx > 0 && c.compare(value, parent)) {
      queue[currentIdx] = parent;
      currentIdx = parentIdx;
      parentIdx = parentIdx / 2;
      parent = queue[parentIdx];
    }

    queue[currentIdx] = value;
    return queue;
  }
}

class Main {
  public static void main(String[] args) {
    int[] q = PriorityQueueComparator.newQueue(0);

    // This comparator turns the min heap into a max heap
    PriorityQueueComparator.Comparator c = (l, r) -> l > r;

    // You have to reassign each time after pushing; if you know you won't need
    // to reallocate then this isn't necessary
    q = PriorityQueueComparator.push(q, -1, c);
    q = PriorityQueueComparator.push(q, 12, c);
    q = PriorityQueueComparator.push(q, 32, c);
    q = PriorityQueueComparator.push(q, 11, c);
    q = PriorityQueueComparator.push(q, 16, c);

    System.out.println(PriorityQueueComparator.pop(q, c));
    System.out.println(PriorityQueueComparator.pop(q, c));
    System.out.println(PriorityQueueComparator.pop(q, c));
    System.out.println(PriorityQueueComparator.pop(q, c));
    System.out.println(PriorityQueueComparator.pop(q, c));
  }
}
