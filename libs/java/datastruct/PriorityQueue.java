package datastruct;

// First index denotes size of underlying heap. Queue always is a min-heap, to
// use as a max-heap multiple input/output by negative 1
class PriorityQueue {

  static float growthFactor = 1.2f;

  static int[] newQueue(int initialSize) { return new int[initialSize + 1]; }
  static int sizeOf(int[] queue) { return queue[0]; }

  static int pop(int[] queue) {
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
      int left = queue[leftIdx], idx, val;

      if (rightIdx < size) {
        if (left >= current)
          break;

        idx = leftIdx;
        val = left;
      } else {
        int right = queue[rightIdx];
        if (current <= right && current <= left)
          break;

        if (right < left) {
          idx = rightIdx;
          val = right;
        } else {
          idx = leftIdx;
          val = left;
        }
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

  static int[] push(int[] queue, int value) {
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
    while (parentIdx > 0 && value < parent) {
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
    int[] q = PriorityQueue.newQueue(1);

    // You have to reassign each time after pushing
    q = PriorityQueue.push(q, -1);
    q = PriorityQueue.push(q, 12);
    q = PriorityQueue.push(q, 32);
    q = PriorityQueue.push(q, 11);
    q = PriorityQueue.push(q, 16);

    System.out.println(PriorityQueue.pop(q));
    System.out.println(PriorityQueue.pop(q));
    System.out.println(PriorityQueue.pop(q));
    System.out.println(PriorityQueue.pop(q));
    System.out.println(PriorityQueue.pop(q));
  }
}
