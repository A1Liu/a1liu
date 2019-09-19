package commands.simple;

import java.util.ArrayList;

/**
 * Tree node of a command tree
 * @author Alyer
 *
 * @param <E> dataType of the tree node
 */
class SimpleNode {
  private String name;
  private Integer id;
  private String helpText;

  private ArrayList<SimpleNode> children;

  SimpleNode(String name) { this(name, null); }

  SimpleNode(String name, Integer id) { this(name, id, null); }

  SimpleNode(String name, Integer id, String helpText) {
    this.name = name;
    this.id = id;
    this.helpText = helpText;
    children = new ArrayList<SimpleNode>(0);
  }

  /**
   * adds a child node of name e
   * @param e name of node
   */
  void addChild(String e) { this.addChild(e, null); }

  /**
   * adds a child with name e and integer identifier id
   * @param e name of node
   * @param id int id of node
   */
  void addChild(String e, Integer id) { this.addChild(e, id, null); }

  /**
   * adds a child with name e and integer identifier id
   * @param e name of node
   * @param id int id of node
   */
  void addChild(String e, Integer id, String helpText) {
    this.addChild(new SimpleNode(e, id, helpText));
  }

  void addChild(SimpleNode node) {
    if (!this.children.contains(node))
      this.children.add(node);
  }

  /**
   * removes child with name e
   * @param e
   */
  void rmChild(String e) { this.children.remove(new SimpleNode(e)); }

  /**
   * checks if this node has a child with name e
   * @param e
   * @return
   */
  boolean containsChild(String e) {
    return this.children.contains(new SimpleNode(e));
  }

  /**
   * gets a reference to the node object with name e that is a child of this
   * node
   * @param e
   * @return
   */
  SimpleNode getChild(String e) {
    int index = this.children.indexOf(new SimpleNode(e));
    return index == -1 ? null : this.children.get(index);
  }

  /**
   * commands are equal if they have the same name.
   */
  public boolean equals(Object o) {
    if (o instanceof SimpleNode) {
      if (((SimpleNode)o).getName() == null) {
        return name == null;
      } else if (((SimpleNode)o).getName().equals(name)) {
        return true;
      }
    }
    return false;
  }

  /**
   * @return the name
   */
  public String getName() { return name; }

  /**
   * @param name the name to set
   */
  public void setName(String name) { this.name = name; }

  /**
   * @return the id
   */
  public Integer getID() { return id; }

  /**
   * @param id the id to set
   */
  public void setID(Integer id) { this.id = id; }

  /**
   * getter for help text
   * @return
   */
  public String getHelp() { return helpText; }

  /**
   * setter for help text
   * @param helpText
   */
  public void setHelp(String helpText) { this.helpText = helpText; }

  /**
   * @return the children
   */
  public ArrayList<SimpleNode> getChildren() { return children; }

  /**
   * @param children the children to set
   */
  public void setChildren(ArrayList<SimpleNode> children) {
    this.children = children;
  }

  public String toString() {
    String childs = "";
    for (int x = 0; x < children.size(); x++) {
      childs += children.get(x).toString().replaceAll("\\n", "\n\t");
    }

    return "\n" + this.name + (id == null ? "" : ":" + id) + childs;
  }
}
