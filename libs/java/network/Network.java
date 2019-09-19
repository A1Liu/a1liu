package network;

import java.util.ArrayList;
import java.util.Enumeration;
import java.util.Hashtable;
import network.LinkedQueue;

/**
 * This class represents the basis of all data structures that involve objects
 * that reference each other in a graph structure. Each vertex in the graph can
 * hold data, and can be identified by any type of object.
 *
 * @author Alyer
 *
 * @param <T> Identifier Object Type (i.e. String, Integer, etc.)
 * @param <E> Vertex Object Type. All Vertices must use the same kind of
 *     identifier
 */
abstract class Network<T, E extends Vertex<T>> {

  private T defaultID;
  private Hashtable<T, E>
      vertices; // I want this hashtable to use a key that is the same as the
                // keytype of the vertex object

  protected Network(T initialID) {
    vertices = new Hashtable<T, E>();
    defaultID = initialID;
  }

  /**
   * default way to add a vertex, without labeling it.
   */
  public abstract boolean addVertex();

  /**
   * add a vertex of specific index
   * @param t the key of the vertex
   * @return true if operation was successful
   */
  public abstract boolean addVertex(T t);

  /**
   * Add a list of vertices from a list of identifiers
   * @param t the list of identifiers
   * @return true if the operation was successful
   */
  public boolean addVertex(T[] t) {
    boolean successful = true;
    for (int index = 0; index < t.length; index++) {
      if (!addVertex(t[index])) // add it, but if the vertex is already there,
                                // then don't.
        successful = false;
      index++;
    }
    return successful;
  }

  /**
   * specified way to add a vertex. All subclasses should use this method to
   * implement addVertex() and addVertex(T t)
   * @param t the identifier for the vertex being added
   * @param e vertex to add
   */
  protected boolean addVertex(T t, E e) {
    if (vertices.containsKey(t))
      return false;
    else {
      vertices.put(t, e);
      incrementID();
      return true;
    }
  }

  /**
   * getter for the integer version of the default key to give to new users
   * @return defaultID the defaultID
   */
  public T getDefaultID() { return defaultID; }

  /**
   * setter for defaultID
   * @param id the initial default id
   */
  protected void setDefaultID(T id) { defaultID = id; }

  /**
   * increases defaultID by one to indicate that a new user has been added to
   * the database
   */
  protected abstract void incrementID();

  /**
   * removes a vertex with identifier id
   * @param id identifier integer of vertex
   * @return whether successful
   */
  public boolean rmVertex(T id) { return vertices.remove(id) != null; }

  /**
   * returns the toString of a specific vertex
   * @param id the id of the vertex
   * @return toString for the specified vertex
   */
  public String vertexToString(T id) { return vertices.get(id).toString(); }

  /**
   * Checks to see if vertex with id is in the network
   * @param id id of the vertex we want to check
   * @return true if the vertex is in the network
   */
  public boolean checkVertex(T id) { return vertices.containsKey(id); }

  /**
   * gets the first vertex in the network
   * @return the first value of the network
   */
  protected E getVertex() {
    return vertices.get(vertices.keys().nextElement());
  }

  /**
   * returns the vertex of a certain id
   * @param id identifier integer of the vertex
   * @return vertex matching id
   */
  protected E getVertex(T id) { return vertices.get(id); }

  /**
   * adds edge of specified length from a vertex to another vertex
   * @param v1 vertex sending edge
   * @param v2 vertex receiving edge
   * @param l length of edge
   * @return true if successful
   */
  public boolean addEdge(T v1, T v2, int l) {
    if (vertices.get(v1) == null)
      return false;
    return vertices.get(v1).addEdge(vertices.get(v2), l);
  }

  /**
   * adds edge of length 1 from a vertex to another vertex
   * @param v1 vertex sending edge
   * @param v2 vertex receiving edge
   * @return true if successful
   */
  public boolean addEdge(T v1, T v2) { return addEdge(v1, v2, 1); }

  /**
   * removes an edge from vertex v1 to vertex v2
   * @param v1 vertex edge is coming from
   * @param v2 vertex edge is going to
   * @return true if successful
   */
  public boolean rmEdge(T v1, T v2) {
    if (vertices.get(v1) == null)
      return false;
    return vertices.get(v1).rmEdge(vertices.get(v2));
  }

  /**
   * removes all edges from vertex v1
   * @param v1 vertex to clear
   * @return true if successful
   */
  public boolean rmEdge(T v) {
    if (vertices.get(v) == null)
      return false;
    vertices.get(v).rmAllEdges();
    return true;
  }

  /**
   * finds length of edge from node v1 to node v2. Returns -1 if the edge
   * doesn't exist
   * @param v1 source node of edge
   * @param v2 destination node of edge
   * @return length of edge
   */
  public int edgeLength(T v1, T v2) {
    if (vertices.get(v1) == null || vertices.get(v2) == null)
      return -1;
    else if (vertices.get(v1).findEdge(vertices.get(v2)) == null)
      return -1;
    return vertices.get(v1).findEdge(vertices.get(v2)).getLength();
  }

  /**
   * finds amount of vertices
   * @return count of vertices
   */
  public int size() { return vertices.size(); }

  /**
   * finds amount of edges in the network
   * @return returns amount of edges
   */
  public int countEdges() {
    int count = 0;
    ArrayList<E> vertexList = listVertices();
    for (int x = 0; x < size(); x++) {
      count += vertexList.get(x).countEdges();
    }
    return count;
  }

  /**
   * Turns network into arrayList of Edges, potentially to be put into cytoscape
   * @return ArrayList of EdgePair objects
   * @throws InterruptedException In case inherited versions use a breadth-first
   *     method
   */
  public ArrayList<EdgePair> listEdges() throws InterruptedException {
    E current;
    ArrayList<E> vertexList = listVertices();
    EdgeList currentEdges;
    ArrayList<EdgePair> edgeList = new ArrayList<EdgePair>();
    for (int x = 0; x < size(); x++) {
      current = vertexList.get(x);
      currentEdges = current.getEdges();
      for (int y = 0; y < currentEdges.size(); y++) {
        EdgePair e = new EdgePair(current, currentEdges.get(y));
        edgeList.add(e);
      }
    }
    return edgeList;
  }

  /**
   * lists all edges of all vertices connected to start vertex
   * @param start vertex
   * @return list of edges
   * @throws InterruptedException
   */
  @SuppressWarnings("unchecked")
  public ArrayList<EdgePair> listEdges(T start) throws InterruptedException {

    // creating necessary containers
    Hashtable<T, Boolean> reached = new Hashtable<T, Boolean>();
    Enumeration<T> keys = enumKeys();
    LinkedQueue<T> queue = new LinkedQueue<T>();
    ArrayList<EdgePair> edgeList = new ArrayList<EdgePair>();
    T current;
    EdgeList currentEdges;
    T currentNeighbor;

    // start at a vertex
    if (size() > 0)
      queue.enqueue(vertices.get(start).getLabel());
    while (reached.size() < vertices.size()) {
      while (!queue.isEmpty()) {
        current = queue.dequeue();
        if (!reached.containsKey(current)) {
          currentEdges = vertices.get(current).getEdges(); // list of edges
          for (int x = 0; x < currentEdges.size(); x++) {
            currentNeighbor = (T)currentEdges.get(x)
                                  .getDestination()
                                  .getLabel(); // neighbor we're looking at
            if (!reached.containsKey(currentNeighbor)) {
              edgeList.add(new EdgePair(
                  vertices.get(current),
                  currentEdges.get(
                      x))); // if the neighbor hasn't been reached, add the edge
              queue.enqueue(currentNeighbor); // only add the neighbor to the
                                              // queue if it wasn't reached and
                                              // isn't already in the queue
            }
          }
          reached.put(current, true);
        }
      }
      if (keys.hasMoreElements())
        start = keys.nextElement();
    }
    return edgeList;
  }

  /**
   * Outputs all edges in the network in csv format.
   * Format is designed for CytoScape, and is in the form
   *
   * 				source, destination, weight
   *
   * @return a cytoscape-formatted csv string
   * @throws InterruptedException
   */
  public String cytoScape() throws InterruptedException {
    String cyto = listEdges().toString();
    cyto = cyto.substring(1, cyto.length() - 1).replaceAll("(?<=\n), ", "");
    return cyto;
  }

  /**
   * returns an enumeration of all keys in the network
   * @return enumeration with all the keys
   */
  protected Enumeration<T> enumKeys() { return vertices.keys(); }

  /**
   * lists the keys in the network.
   * @return An ArrayList of keys
   */
  public ArrayList<T> keys() {
    ArrayList<T> vertexList = new ArrayList<T>();
    Enumeration<T> keys = enumKeys();

    while (keys.hasMoreElements()) {
      vertexList.add(keys.nextElement());
    }
    return vertexList;
  }

  /**
   * Turns the network into an ArrayList of vertices
   * @return an ArrayList of vertices
   */
  protected ArrayList<E> listVertices() {

    ArrayList<E> vertexList = new ArrayList<E>();
    Enumeration<T> keys = enumKeys();

    while (keys.hasMoreElements()) {
      vertexList.add(vertices.get(keys.nextElement()));
    }
    return vertexList;
  }

  /**
   * toString method for Network. It's purpose is fulfilled by other methods,
   * inheriting classes will do stuff with this.
   */
  @Override
  public String toString() {
    return null;
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
 * This class represents a labeled point. If a point is the common end point of
 * at least 2 line segments, a vertex is a point with an attached label object
 * of type T. The parameter is used to prevent weird interactions with the hash
 * table and such. Also it means that edges can be stored in vertices instead of
 * being stored partially in the network class.
 *
 * @author Alyer
 *
 * @param <T>
 */
class Vertex<T> extends Point {

  private final T label;

  Vertex(T t) throws IllegalArgumentException {
    super();

    if (t == null)
      throw new IllegalArgumentException("Vertex label cannot be null.");

    label = t;
  }

  @Override
  T getLabel() {
    return label;
  }

  /**
   * toString for vertices. Lists all vertex labels for its edges, as well as
   * edge lengths
   * @return identifier for vertex and all edges of vertex
   */
  @Override
  public String toString() {

    try {
      int label = Integer.parseInt(getLabel().toString());
      return "\nV" + label + ": [" + getEdges().toString() + "]";
    } catch (NumberFormatException e) {
      String label = "'" + getLabel().toString() + "'";
      return "\nV" + label + ": [" + getEdges().toString() + "]";
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
 * This class represents the most basic form of a vertex. i.e. a vertex labeled
 * "null".
 * @author Alyer
 *
 */
abstract class Point implements Comparable<Point> {

  private EdgeList edges;

  protected Point() { edges = new EdgeList(); }

  @Override
  public int compareTo(Point p) {
    return countEdges() - p.countEdges();
  }

  /**
   * gets a list of the edges
   * @return EdgeList of edges
   */
  EdgeList getEdges() { return edges; }

  /**
   * counts edges
   * @return amount of edges coming from vertex
   */
  int countEdges() { return edges.size(); }

  /**
   * adds an edge
   * @param p vertex to point edge to
   * @param l length of edge
   * @return whether edge was successfully added
   */
  boolean addEdge(Point p, int l) {
    Edge newEdge = new Edge(p, l);
    return addEdge(newEdge);
  }

  /**
   * adds an edge
   * @param newEdge edge to be added
   * @return whether edge was successfully added
   */
  boolean addEdge(Edge newEdge) { return edges.add(newEdge); }

  /**
   * This method returns the closest possible match to the given vertex
   * @param e edge to find
   * @return the edge with the same destination as e, or null if there is none.
   */
  Edge findEdge(Edge e) {
    if (e.getDestination() == null || edges.size() == 0)
      return null;
    return edges.indexOf(e) == -1 ? null : edges.get(edges.indexOf(e));
  }

  /**
   * This method returns the closest possible match to the given vertex
   * @param p destination of edge to find
   * @return the edge with destination v, or null if there is none.
   */
  Edge findEdge(Point p) {
    Edge e = new Edge(p, 0);
    return findEdge(e);
  }

  /**
   * removes all edges from the point
   */
  void rmAllEdges() { edges = new EdgeList(); }

  /**
   * moves an edge
   * @param e1 edge to remove
   * @param e2 edge to add
   * @return true if successful
   */
  boolean setEdge(Edge e1, Edge e2) {
    int index = edges.indexOf(e1);
    Edge e = null;
    if (index != -1)
      e = edges.get(index);
    if (edges.remove(e1)) {
      if (edges.add(e2)) {
        return true;
      }
      edges.add(e);
    }
    return false;
  }

  /**
   * removes the edge with the same destination as input edge
   * @param e edge to remove
   * @return whether the edge was present in the vertex to begin with
   */
  boolean rmEdge(Edge e) { return edges.remove(e); }

  /**
   * removes the edge with destination of input edge
   * @param v destination of edge to remove
   * @return whether the edge was present in the vertex to begin with
   */
  boolean rmEdge(Point p) {
    Edge e = new Edge(p, 0);
    return rmEdge(e);
  }

  /**
   * getter for label
   * @return label
   */
  abstract Object getLabel();

  /**
   * toString for vertices
   * @return identifier for vertex and all edges of vertex
   */
  @Override
  public String toString() {
    return "{Point with " + countEdges() + " Edges.}";
  }
}
