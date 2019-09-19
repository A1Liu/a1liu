package network;

import java.util.ArrayList;
import java.util.Enumeration;
import java.util.Hashtable;
import network.LinkedQueue;

/**
 * This class represents an Undirected graph
 * @author Alyer
 *
 */
public class UndirectedGraph extends Graph<Vertex<Integer>> {

  UndirectedGraph() {}

  @Override
  public boolean addVertex(Integer t) {
    Vertex<Integer> v = new Vertex<Integer>(t);
    return addVertex(t, v);
  }

  @Override
  public boolean addEdge(Integer v1, Integer v2) {
    return super.addEdge(v1, v2) && super.addEdge(v2, v1);
  }

  @Override
  public boolean addEdge(Integer v1, Integer v2, int l) {
    return super.addEdge(v1, v2, l) && super.addEdge(v2, v1, l);
  }

  @Override
  public boolean rmVertex(Integer id) {
    return this.rmEdge(id) && super.rmVertex(id);
  }

  @Override
  public boolean rmEdge(Integer v1, Integer v2) {
    boolean b = super.rmEdge(v1, v2);
    return super.rmEdge(v2, v1) || b;
  }

  @Override
  public boolean rmEdge(Integer v) {
    Vertex<Integer> toDelete = getVertex(v);

    if (toDelete == null)
      return false;

    EdgeList edges = toDelete.getEdges();

    for (int x = 0; x < edges.size(); x++) {
      edges.get(x).getDestination().rmEdge(toDelete);
    }
    super.rmEdge(v);

    return true;
  }

  @Override
  public int countEdges() {
    int count = 0;
    ArrayList<Vertex<Integer>> vertexList = listVertices();
    for (int x = 0; x < size(); x++) {
      count += vertexList.get(x).countEdges();
    }
    return count / 2;
  }

  @Override
  public ArrayList<EdgePair> listEdges()
      throws InterruptedException { // I need to use a breadth-first algorithm
                                    // here to improve computation time.

    if (size() == 0)
      return null;

    // creating necessary containers
    Hashtable<Integer, Boolean> reached =
        new Hashtable<Integer,
                      Boolean>(); // hashtable makes checking which nodes have
                                  // been reached into a linear operation
    LinkedQueue<Integer> queue =
        new LinkedQueue<Integer>(); // The nodes to check
    ArrayList<EdgePair> edgeList =
        new ArrayList<EdgePair>(); // List of edges to be outputted
    Enumeration<Integer> vertexList =
        enumKeys(); // list of all vertices to make sure completely isolated
                    // subgraphs aren't ignored
    Integer current;
    EdgeList currentEdges;   // Current edges
    Integer currentNeighbor; // current neighbor of current vertex
    Integer start = getVertex(vertexList.nextElement())
                        .getLabel(); // The vertex the algorithm starts on

    // keep going until the entire network is traversed, including all isolated
    // graphs
    while (reached.size() < size()) {
      // start at a vertex
      if (!reached.containsKey(start)) {
        queue.enqueue(start);
        while (!queue.isEmpty()) {
          current = queue.dequeue();
          if (!reached.containsKey(
                  current)) { // make sure we don't iterate over the same things
                              // over and over
            currentEdges = getVertex(current).getEdges(); // list of edges
            for (int x = 0; x < currentEdges.size(); x++) {
              currentNeighbor = (Integer)currentEdges.get(x)
                                    .getDestination()
                                    .getLabel(); // neighbor we're looking at
              if (!reached.containsKey(currentNeighbor)) {
                edgeList.add(new EdgePair(
                    getVertex(current),
                    currentEdges.get(x))); // if the neighbor hasn't been
                                           // reached, add the edge
                queue.enqueue(currentNeighbor); // only add the neighbor to the
                                                // queue if it wasn't reached
              }
            }
            reached.put(current, true); // record that a node has been reached
          }
        }
      }
      if (vertexList
              .hasMoreElements()) // make sure that separated graphs aren't
                                  // missed based on the starting node.
        start = vertexList.nextElement();
    }
    return edgeList;
  }
}
