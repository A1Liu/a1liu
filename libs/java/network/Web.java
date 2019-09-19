package network;

/**
 * This class represents a web, which contains labeled vertices and unweighted,
 * undirected edges. I might play around with traversal later with this, just
 * wanted to have it for now.
 * @author Alyer
 *
 */
class Web extends UndirectedGraph {

  Web() {}

  /**
   * This method adds an edge from v1 to v2 to the network.
   * Edges don't have weights, so length values are discarded.
   */
  @Override
  public boolean addEdge(Integer v1, Integer v2, int l) {
    return super.addEdge(v1, v2);
  }
}
