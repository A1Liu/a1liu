package network;

import static network.Util.isNumber;

import java.util.ArrayList;
import java.util.Enumeration;
import java.util.Hashtable;
import network.LinkedQueue;

/**
 * need to make new vertex object that holds values, otherwise this will become
 * complicated quickly
 * @author liu_albert
 *
 */
public class RatingsGraph extends Graph<RatingsNode> {

  RatingsGraph() {}

  /**
   * make a copy of an existing RatingsGraph, including its vertices' states
   * @param g graph to copy
   * @throws InterruptedException if something fucks up with the Queue
   */
  RatingsGraph(RatingsGraph g) throws InterruptedException {
    String[] input = g.cytoScape().split("\n");
    for (int x = 0; x < input.length; x++) {
      this.loadEdge(input[x]);
    }

    Enumeration<Integer> vertices = g.enumKeys();
    Integer current = 0;
    while (vertices.hasMoreElements()) {
      current = vertices.nextElement();
      this.getVertex().setNode(g.getVertex(current).getR(),
                               g.getVertex(current).getV());
    }
  }

  @Override
  public boolean addVertex(Integer t) {
    if (getDefaultID() > 127 || (t.toString().charAt(0) < 48))
      return false;
    RatingsNode v = new RatingsNode(t);
    return addVertex(t, v);
  }

  /**
   * Traverses the network and updates it, starting from the first listed node
   * in the network
   * @throws InterruptedException
   * @throws IllegalArgumentException
   */
  public void update() throws InterruptedException, IllegalArgumentException {
    if (size() == 0)
      return;

    update(getVertex().getLabel());
  }

  /**
   * update the network i times
   * @param i the amount of iterations to update the network
   * @throws IllegalArgumentException
   * @throws InterruptedException
   */
  public void update(int i)
      throws IllegalArgumentException, InterruptedException {
    if (size() == 0)
      return;
    for (int x = 0; x < i; x++) {
      update();
    }
  }

  /**
   * Updates the network, starting at node t
   * @param t the starting point of the breadth-first iteration
   * @throws InterruptedException If the queue screws up
   * @throws IllegalArgumentException If t isn't a node
   */
  public void update(Integer t)
      throws InterruptedException, IllegalArgumentException {
    LinkedQueue<Integer> queue = new LinkedQueue<Integer>();

    if (size() == 0)
      return;

    if (getVertex(t) == null)
      throw new IllegalArgumentException("'" + t.toString() +
                                         "' is not a valid node identifier.");

    // creating necessary containers
    Hashtable<Integer, Boolean> reached = new Hashtable<Integer, Boolean>();
    Enumeration<Integer> vertexList = enumKeys();
    ArrayList<Edge> currentEdges;
    Integer current;
    Integer currentNeighbor;
    Integer start = t;

    while (reached.size() < size()) {
      // start at a vertex
      if (!reached.containsKey(start)) {
        queue.enqueue(start);
        while (!queue.isEmpty()) {
          current = queue.dequeue();
          if (!reached.containsKey(current)) {
            updateVertex(current);
            currentEdges = getVertex(current).getRatings(); // list of edges
            for (int x = 0; x < currentEdges.size(); x++) {
              currentNeighbor = (Integer)currentEdges.get(x)
                                    .getDestination()
                                    .getLabel(); // neighbor we're looking at
              if (!reached.containsKey(currentNeighbor)) {
                queue.enqueue(currentNeighbor); // only add the neighbor to the
                                                // queue if it wasn't reached and
                                                // isn't already in the queue
              }
            }
            reached.put(current, true);
          }
        }
      }
      if (vertexList.hasMoreElements())
        start = vertexList.nextElement();
    }
  }

  /**
   * This outputs a String array, where each element is a line in a csv file.
   * By adding newline characters between each element, it can be directly
   * turned into a csv
   * @param i amount of update iterations
   * @return pseudo-csv, in the form of a string array
   * @throws IllegalArgumentException if update screws up
   * @throws InterruptedException if update screws up
   */
  public String[] updateCSV(int i)
      throws IllegalArgumentException, InterruptedException {

    if (size() == 0)
      return null;

    String[] output = new String[i * 2 + 7];
    String commas = "";
    for (int x = 0; x < this.keys().size() - 1; x++) {
      commas += ",";
    }

    output[0] = "Ratings," + i + " iterations," + commas;
    output[1] = "Iteration," + this.keys().toString().substring(
                                   1, this.keys().toString().length() - 1);
    output[2] = "0," + getRatings().toString().substring(
                           1, getRatings().toString().length() - 1);
    output[i + 3] = commas + ",";
    output[i + 4] = "Vote Counts," + i + " iterations," + commas;
    output[i + 5] = "Iteration," + this.keys().toString().substring(
                                       1, this.keys().toString().length() - 1);
    output[i + 6] = "0," + getVotes().toString().substring(
                               1, getVotes().toString().length() - 1);
    for (int x = 0; x < i; x++) {
      update();
      output[x + 3] = (x + 1) + "," +
                      getRatings().toString().substring(
                          1, getRatings().toString().length() - 1);
      output[x + i + 7] = (x + 1) + "," +
                          getVotes().toString().substring(
                              1, getVotes().toString().length() - 1);
    }
    return output;
  }

  /**
   * update a specific vertex
   * @param t identifier of the vertex
   */
  private void updateVertex(Integer t) { this.getVertex(t).update(); }

  @Override
  public void loadEdge(String edge) {
    String[] edges = edge.split(",");
    if (edges.length > 2)
      if (isNumber(edges[2]) && Integer.parseInt(edges[2]) > 5)
        edges[2] = "5";
    super.loadEdge(edges);
  }

  /**
   * updates until the network passes a threshold for accuracy (5 repetitions of
   * the same rounded rating value across all nodes)
   * @return a String Array with an output similar to that of updateCSV, but
   *     with only the 0th iteration and the last 10 iterations, as well as the
   *     cytoscape network (without any edges that go into themselves)
   * @throws InterruptedException
   * @throws IllegalArgumentException
   */
  public String[] updateLoop()
      throws IllegalArgumentException, InterruptedException {
    if (size() == 0)
      return null;
    LinkedQueue<String> ratings = new LinkedQueue<String>();
    LinkedQueue<String> votes = new LinkedQueue<String>();
    String[] output = new String[29];
    String commas = "";
    for (int x = 0; x < this.keys().size() - 1; x++) {
      commas += ",";
    }

    output[1] = "Iteration," + this.keys().toString().substring(
                                   1, this.keys().toString().length() - 1);
    output[2] = "0," + getRatings().toString().substring(
                           1, getRatings().toString().length() - 1);
    output[13] = commas + ",";

    output[15] = "Iteration," + this.keys().toString().substring(
                                    1, this.keys().toString().length() - 1);
    output[16] = "0," + getVotes().toString().substring(
                            1, getVotes().toString().length() - 1);

    System.out.println(output[16]);

    int x = 0;
    for (x = 0; x < 10; x++) {
      update();
      output[x + 3] = (x + 1) + "," +
                      getRatings().toString().substring(
                          1, getRatings().toString().length() - 1);
      output[x + 17] = (x + 1) + "," +
                       getVotes().toString().substring(
                           1, getVotes().toString().length() - 1);
      ratings.enqueue(output[x + 3]);
      votes.enqueue(output[x + 17]);
    }

    while (
        !output[((x - 2) % 10) + 3]
             .substring(output[((x - 2) % 10) + 3].indexOf(','))
             .equals(output[((x - 1) % 10) + 3].substring(
                 output[((x - 1) % 10) + 3].indexOf(
                     ',')))) { // while the  most recent iteration results and
                               // its preceding results dont match, keep going
      update();
      output[(x % 10) + 3] =
          (x + 1) + "," +
          getRatings().toString().substring(
              1, getRatings().toString().length() -
                     1); // output holds the 10 most recent results
      output[(x % 10) + 17] = (x + 1) + "," +
                              getVotes().toString().substring(
                                  1, getVotes().toString().length() - 1);
      ratings.dequeue();
      ratings.enqueue(
          output[(x % 10) + 3]); // queue holds the 10 most recent as well
      votes.dequeue();
      votes.enqueue(output[(x % 10) + 17]);
      x++;
    }

    for (int y = 0; y < 10; y++) {
      output[y + 3] = ratings.dequeue(); // fill output with 10 most recent
      output[y + 17] = votes.dequeue();
    }

    output[0] = "Ratings," + (x) + " iterations," +
                commas; // output amount of iterations
    output[14] = "Vote Counts," + (x) + " iterations," + commas;
    output[27] = "," + commas;
    output[28] = this.cytoScape();
    return output;
  }

  /**
   * get a list of ratings of each of the nodes
   * @return an arraylist of ratings
   */
  private ArrayList<Double> getRatings() {
    ArrayList<RatingsNode> vertices = listVertices();
    ArrayList<Double> ratings = new ArrayList<Double>();
    for (int x = 0; x < vertices.size(); x++) {
      ratings.add(Math.floor(vertices.get(x).getR() * 100) / 100);
    }
    return ratings;
  }

  /**
   * Get the vote count of each of the nodes
   * @return an arraylist of vote counts
   */
  private ArrayList<Double> getVotes() {
    ArrayList<RatingsNode> vertices = listVertices();
    ArrayList<Double> votes = new ArrayList<Double>();
    for (int x = 0; x < vertices.size(); x++) {
      votes.add(Math.floor(vertices.get(x).getV() * 100) / 100);
    }
    return votes;
  }

  @Override
  public boolean addEdge(Integer n1, Integer n2, int r) {
    if (getVertex(n1) == null || getVertex(n2) == null)
      return false;
    getVertex(n1).rate(getVertex(n2), r);
    return true;
  }

  @Override
  public void incrementID() {
    return;
  }
}

/**
 * edges in the inherited edgelist are the ratings this node has received
 * Edges in the ratings Edgelist are the ratings this node has given to others
 * @author Alyer
 *
 */
class RatingsNode extends Vertex<Integer> {

  private double r;         // this node's rating
  private double v;         // this node's total votes
  private EdgeList ratings; // The list of ratings this node has made

  RatingsNode(Integer t) {
    super(t);
    r = 1.0;
    v = 1.0;
    ratings = new EdgeList();
    // adding self to the list of nodes that have rated this node. We don't need
    // to add self to the list we've rated because we already have a reference to
    // this node.
    super.addEdge(
        new Edge(this, 1)); // addEdge adds to the edgelist, which is the list
                            // of ratings this node has received
  }

  @Override
  boolean addEdge(Edge e) {

    if (e.getDestination() instanceof RatingsNode &&
        !(e.getDestination() == this)) {
      return super.addEdge(e);
    }
    return false;
  }

  /**
   * Adds a rating from this node to another node
   * @param n the node being rated
   * @param r the rating being given
   * @return
   */
  void rate(RatingsNode n, int r) {
    if (ratings.add(new Edge(n, r))) {
      n.addEdge(new Edge(this, r));
    } else {
      ratings.remove(new Edge(n, r));
      n.rmEdge(new Edge(this, r));
      ratings.add(new Edge(n, r));
      n.addEdge(new Edge(this, r));
    }
  }

  /**
   * getter for ratings list
   * @return ratings edgelist
   */
  EdgeList getRatings() { return this.ratings; }

  /**
   * recalculates the value of r and v and stores them
   * NOTE: Need to move this method to the RatingsGraph Class and remake it.
   */
  void update() {
    double ratingSum = 0;
    double votes = 0;
    RatingsNode current;

    for (int x = 0; x < this.countEdges(); x++) {
      current = (RatingsNode)this.getEdges().get(x).getDestination();
      ratingSum += this.getEdges().get(x).getLength() * current.getPower();
      votes += current.getPower();
    }

    r = ratingSum / votes;
    v = votes;
  }

  /**
   * Function to determine the power of a node given its rating and its total
   * votes
   * @param r rating of the node
   * @param v votes the node has received
   * @return the power of the node
   */
  static double getPower(double r, double v) {
    double x =
        2.0 -
        Math.pow(5, 1 - v); // first parameter of Math.power is the speed at
                            // which power increases relative to votes received
    return Math.pow(Math.pow(2, r), x / 4.0);
  }

  /**
   * calculates the power of a specified rating node
   * @param n the node whose power we are calculating
   * @return the voting power
   */
  static double getPower(RatingsNode n) { return getPower(n.getR(), n.getV()); }

  /**
   * calculates the power of this rating node
   * @return the power
   */
  double getPower() { return getPower(this.r, this.v); }

  /**
   * getter for rating
   * @return rating
   */
  double getR() { return r; }

  /**
   * setter for node's rating and votes
   * @param r
   * @param v
   */
  void setNode(double r, double v) {
    this.r = r;
    this.v = v;
  }

  /**
   * getter for the vote count
   * @return vote count
   */
  double getV() { return v; }
}
