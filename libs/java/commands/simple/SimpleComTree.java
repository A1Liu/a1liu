package commands.simple;

/**
 * Represents command tree data structure. Includes methods to add to a single
 * level or through a single path.
 * @author Alyer
 *
 * @param <E> data type that the tree holds
 */
class SimpleComTree {

  private SimpleNode root;

  public SimpleComTree() { root = new SimpleNode("Root"); }

  /**
   * adds a path of nodes based on a string of node names
   * @param elist
   */
  public void addPath(String[] elist) { addPath(elist, null); }

  /**
   * getter for the root node
   * @return the root node
   */
  public SimpleNode getRoot() { return root; }

  /**
   * adds a path in the tree that includes all elements of e, in order
   * @param elist the list of elements that should be added
   */
  public void addPath(String[] elist, Integer id) {
    SimpleNode wd = root;
    for (String element : elist) {
      wd.addChild(element);
      wd = wd.getChild(element);
    }
    wd.setID(id);
  }

  /**
   * adds a list of child nodes at a specific path
   * @param ePath path to where the nodes should be added
   * @param children list of nodes to add
   */
  public void addChildren(String[] ePath, String[] children) {
    SimpleNode wd = root;
    try {
      for (String element : ePath) {
        wd = wd.getChild(element);
      }
    } catch (NullPointerException e) {
      return;
    }
    for (String element : children) {
      wd.addChild(element);
    }
  }

  /**
   * returns the annotated structure of this command tree
   */
  public String toString() {
    String childs = "";
    for (int x = 0; x < root.getChildren().size(); x++) {
      childs += root.getChildren().get(x).toString();
    }
    return childs;
  }
}
