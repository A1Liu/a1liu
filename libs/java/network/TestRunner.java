package network;

// import java.io.BufferedReader;
// import java.io.InputStreamReader;
import static network.Util.writeFile;

import java.io.IOException;

/**
 * This class is the test harness for methods in the network package.
 *
 * @author Alyer
 *
 */
public class TestRunner {

  public static void main(String args) {
    System.out.println(RatingsNode.getPower(4.61, 1500));
  }

  public static void main(String[] args)
      throws IOException, IllegalArgumentException, InterruptedException {

    RatingsGraph graph = new RatingsGraph();
    // BufferedReader input = new BufferedReader(new
    // InputStreamReader(System.in)); String edge = "";
    String outPath = "out/Iterations.csv";
    String path = "lib/Network.csv";
    path = "C:/Users/Alyer/Desktop/Network - Out.csv";
    graph.loadNetwork(path);

    writeFile(outPath, graph.updateLoop());
    System.out.println("Enter in new edge.");

    /*while (!edge.equals("foo")) {
            edge = input.readLine();
            if (!edge.equals("foo")) {
                    graph.loadEdge(edge);
                    String[] a = graph.updateLoop();
                    /*for (int x = 0; x < a.length; x++) {
                            System.out.println(a[x]);
                    }
                    writeFile(outPath,a);
            }
    }*/

    System.out.println(graph.countEdges());
    System.out.println(graph.size());
    System.out.println(graph.countEdges() / graph.size());
  }
}
