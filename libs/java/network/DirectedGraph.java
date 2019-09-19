package network;

/**
 * This class represents a Directed Graph of named vertices and weighted arrows
 * between vertices. Arrows directed at their source vertex are allowed.
 * @author Alyer
 *
 */
public class DirectedGraph extends Graph<Vertex<Integer>> {

  DirectedGraph() {}

  @Override
  public boolean addVertex(Integer t) {
    Vertex<Integer> v = new Vertex<Integer>(t);
    return addVertex(t, v);
  }
}
