package network;

import java.util.ArrayList;

/**
 * This class is the Edge-specific ArrayList object that all point objects
 * contain. Its goal is to hold the edges coming from a specific vertex
 * @author Alyer
 *
 */
class EdgeList extends ArrayList<Edge> {

  /**
   *
   */
  private static final long serialVersionUID = 1L;

  EdgeList() {}

  /**
   * constructor to create an edgeList from an existing ArrayList
   * @param a ArrayList to base the edgelist off of
   */
  EdgeList(ArrayList<Edge> a) {
    for (int x = 0; x < a.size(); x++) {
      add(a.get(x));
    }
  }

  /**
   * constructor to create an edgeList from an existing Array
   * @param a Array to base the edgelist off of
   */
  EdgeList(Edge[] a) {
    for (int x = 0; x < a.length; x++) {
      add(a[x]);
    }
  }

  /**
   * adds the element e if it's not already in the list
   * @param e the element that we want to add
   * @return true if successful
   */
  @Override
  public boolean add(Edge e) {

    if (e == null)
      return false;

    if (e.getDestination() == null)
      return false;

    if (this.contains(e))
      return false;

    return super.add(e);
  }
}

/* --------------------------------------------------------------------------------------------------------------------------------------------------
 * --------------------------------------------------------------------------------------------------------------------------------------------------
 * --------------------------------------------------------------------------------------------------------------------------------------------------
 * --------------------------------------------------------------------------------------------------------------------------------------------------
 * --------------------------------------------------------------------------------------------------------------------------------------------------
 * --------------------------------------------------------------------------------------------------------------------------------------------------
 */

class Edge implements Comparable<Edge> {

  private Point destination;
  private int length;

  Edge(Point v, int l) {
    destination = v;
    length = Math.abs(l);
  }

  @Override
  public int compareTo(Edge e) {
    return this.getLength() - e.getLength();
  }

  /**
   * This checks whether an edge is "equal" to another edge.
   * It only looks at destination to make other methods easier to implement.
   * To check length, use compareTo
   */
  @Override
  public boolean equals(Object o) {

    if (!(o instanceof Edge))
      return false;

    if (this.destination == ((Edge)o).getDestination())
      return true;

    return false;
  }

  /**
   * getter for length
   * @return length
   */
  public int getLength() { return length; }

  /**
   * setter for length
   * @param l length
   */
  void setLength(int l) { length = Math.abs(l); }

  /**
   * getter for destination
   * @return node that the edge is pointing to
   */
  public Point getDestination() { return destination; }

  /**
   * setter for destination
   * @param d destination
   */
  void setDestination(Point d) { destination = d; }

  /**
   * Returns the destination and length of each edge in String form.
   */
  @Override
  public String toString() {
    try {
      int label = Integer.parseInt(destination.getLabel().toString());
      return "(V" + label + ", " + length + ")";
    } catch (NumberFormatException e) {
      String label = "'" + destination.getLabel() + "'";
      return "(V" + label + ", " + length + ")";
    }
  }
}

/* --------------------------------------------------------------------------------------------------------------------------------------------------
 * --------------------------------------------------------------------------------------------------------------------------------------------------
 * --------------------------------------------------------------------------------------------------------------------------------------------------
 * --------------------------------------------------------------------------------------------------------------------------------------------------
 * --------------------------------------------------------------------------------------------------------------------------------------------------
 * --------------------------------------------------------------------------------------------------------------------------------------------------
 */

/**
 * This class allows for easier implementation of listing full networks. Might
 * get rid of it later depending on how I restructure code, but right now it
 * does its job fine.
 *
 * This could probably be removed if I restructure the code just a little bit.
 * @author Alyer
 *
 */
class EdgePair extends Edge {

  private final Point source;

  EdgePair(Point p1, Point p2) { this(p1, p2, 1); }

  EdgePair(Point p1, Point p2, int l) {
    super(p2, l);
    source = p1;
  }

  EdgePair(Point p, Edge e) { this(p, e.getDestination(), e.getLength()); }

  /**
   * getter for source point
   * @return source
   */
  Point getSource() { return source; }

  @Override
  public boolean equals(Object o) {
    if (!(o instanceof EdgePair))
      return false;

    if (((EdgePair)o).getDestination() == getDestination() &&
        ((EdgePair)o).getSource() == getSource())
      return true;

    return false;
  }

  /**
   * returns the source, destination, and length of the edgepair.
   * The output is formatted as comma separated values.
   */
  public String toString() {
    return (getLength() == 0)
        ? source.getLabel().toString() + "," +
              getDestination().getLabel().toString()
        : source.getLabel().toString() + "," +
              getDestination().getLabel().toString() + "," + getLength() + "\n";
  }
}
