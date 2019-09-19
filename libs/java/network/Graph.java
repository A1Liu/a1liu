package network;

import static network.Util.isNumber;
import static network.Util.readFile;

import java.io.IOException;
import java.util.ArrayList;

/**
 * This class represents the basic implementation of a graph of labeled
 * vertices. I'll be using it to test different algorithms, and to analyze
 * runtimes.
 *
 * This class also has methods specific to Integer-labeled networks. Since it's
 * the base form of a graph, it is a directed graph.
 * @author Alyer
 *
 * @param <T> The type of vertex object to include. Parameterization used to
 *     allow vertices to hold extra data, like node-specific values.
 */
public abstract class Graph<T extends Vertex<Integer>>
    extends Network<Integer, T> {

  /**
   *
   */
  protected Graph() { super(0); }

  // These methods all other packages to access these graphs.
  public static RatingsGraph getRatingsGraph() { return new RatingsGraph(); }
  public static DirectedGraph getGraph() { return new DirectedGraph(); }
  public static Web getWeb() { return new Web(); }
  public static UndirectedGraph getUndirectedGraph() {
    return new UndirectedGraph();
  }

  @Override
  public boolean addVertex() {
    if (addVertex(getDefaultID())) {
      return true;
    }
    int x = 0;
    while (!addVertex(x)) {
      x++;
    }
    return true;
  }

  @Override
  protected void incrementID() {
    setDefaultID(getDefaultID() + 1);
  }

  /**
   * loads edges into the network
   * @param document the name of the document to add from
   * @throws IOException if the document doesn't exist
   */
  public void loadNetwork(String document) throws IOException {
    ArrayList<String> input = readFile(document);
    for (int x = 0; x < input.size(); x++) {
      loadEdge(input.get(x));
    }
  }

  /**
   * loads an edge into the network given comma separated values
   * @param edge edge to add
   */
  public void loadEdge(String edge) { loadEdge(edge.split(",")); }

  /**
   * loads an edge into the network given an array of strings
   * @param edge the array of strings to input
   */
  protected void loadEdge(String[] edge) {

    if (edge.length < 3) {
      return;
    } // edge should be like this: [SourceName,DestinationName,weight] In this
      // case the names are also integers

    for (int x = 0; x < 3; x++) {
      if (!isNumber(edge[x])) {
        return;
      } // checking if each string is an integer
    }

    int id1 = Integer.parseInt(edge[0]);
    int id2 = Integer.parseInt(edge[1]);

    if (getVertex(Integer.parseInt((edge[0]))) == null) {
      addVertex(id1); // If it's not in the network, add the vertex first
    }
    if (getVertex(Integer.parseInt((edge[1]))) == null) {
      addVertex(id2);
    }
    addEdge(id1, id2, Integer.parseInt(edge[2])); // add the edge
  }
}
