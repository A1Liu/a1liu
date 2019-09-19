package data;

import java.util.ArrayList;

/**
 * Tree class
 * @author Alyer
 *
 * @param <E> data type that the tree holds
 */
public class Tree<E> {

  TreeNode<E> root;

  public Tree() { root = new TreeNode<E>(null); }

  /**
   * adds a path in the tree that includes all elements of e, in order
   * @param elist the list of elements that should be added
   */
  public void addPath(E[] elist) {
    TreeNode<E> wd = root;
    for (E element : elist) {
      wd.addChild(element);
      wd = wd.getChild(element);
    }
  }

  /**
   * adds a list of child nodes at a specific path
   * @param ePath path to where the nodes should be added
   * @param children list of nodes to add
   */
  public void addChildren(E[] ePath, E[] children) {
    TreeNode<E> wd = root;
    try {
      for (E element : ePath) {
        wd = wd.getChild(element);
      }
    } catch (NullPointerException e) {
      return;
    }
    for (E element : children) {
      wd.addChild(element);
    }
  }
}

/**
 * Tree node of a generalized tree
 * @author Alyer
 *
 * @param <E> dataType of the tree node
 */
class TreeNode<E> {
  private E data;
  private ArrayList<TreeNode<E>> children;

  TreeNode(E e) {
    data = e;
    children = new ArrayList<TreeNode<E>>(0);
  }

  E getData() { return data; }

  void setData(E data) { this.data = data; }

  void addChild(E e) {
    if (!this.children.contains(new TreeNode<E>(e)))
      this.children.add(new TreeNode<E>(e));
  }

  void rmChild(E e) { this.children.remove(new TreeNode<E>(e)); }

  TreeNode<E> getChild(E e) {
    int index = this.children.indexOf(new TreeNode<E>(e));
    return index == -1 ? null : this.children.get(index);
  }

  public boolean equals(Object o) {
    if (o instanceof TreeNode<?>) {
      if (((TreeNode<?>)o).getData().equals(data)) {
        return true;
      }
    }
    return false;
  }
}
