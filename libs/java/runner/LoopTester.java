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
public abstract class LoopTester extends SimpleTester {

  public LoopTester() { this(true); }

  public LoopTester(boolean input) { super(input); }

  @Override
  public void run() {
    while (true) {
      super.run();
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
