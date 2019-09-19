package runner;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

/**
 * A simple tester to test stuff. Nothing fancy, uses console line for input and
 * output.
 * @author aliu
 *
 */
public abstract class SimpleTester implements Runnable {

  private final BufferedReader reader;
  private final boolean input;

  public SimpleTester() { this(true); }

  public SimpleTester(boolean input) {
    this.input = input;
    reader = new BufferedReader(new InputStreamReader(System.in));
  }

  @Override
  public void run() {
    try {
      Object output = execute(this.input ? reader.readLine() : null);
      System.out.println(output == null ? "<null>" : output.toString());
    } catch (IOException e) {
      e.printStackTrace();
    }
  }

  /**
   * Takes input directly from command line, and outputs object result. Object
   * result is printed using its toString() method.
   * @param input String line from System.in
   * @return object result
   */
  public abstract Object execute(String input);
}
