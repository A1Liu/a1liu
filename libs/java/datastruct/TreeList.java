package datastruct;

abstract class TreeList<Value> {
  public final int guide;
  private TreeList(int guide) { this.guide = guide; }

  public abstract Value get(int index);
  // public abstract TreeList<Value> add(Value value);

  static class Internal<Value> extends TreeList<Value> {
    TreeList<Value> child0, child1, child2;

    private Internal(Internal<Value> child0, Internal<Value> child1) {
      super(child0.guide + child1.guide);
      this.child0 = child0;
      this.child1 = child1;
      this.child2 = null;
    }

    private Internal(Internal<Value> child0, Internal<Value> child1,
                     Internal<Value> child2) {
      super(child0.guide + child1.guide + child2.guide);
      this.child0 = child0;
      this.child1 = child1;
      this.child2 = child2;
    }

    public Value get(int index) {
      if (index < child0.guide) {
        return child0.get(index);
      }

      int index2 = index - child0.guide;
      if (index2 < child1.guide) {
        return child1.get(index2);
      }

      index2 -= child1.guide;
      if (child2 != null && index2 < child2.guide) {
        return child2.get(index);
      }

      throw new IndexOutOfBoundsException(index);
    }

    static class Leaf<Value> extends TreeList<Value> {
      Value value;

      private Leaf(Value value) {
        super(1);
        this.value = value;
      }

      public Value get(int index) {
        if (index != 0) {
          throw new IndexOutOfBoundsException(index);
        }

        return this.value;
      }
    }
  }
}
