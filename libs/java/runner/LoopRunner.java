package runner;

/**
 * Implementation of Runner that executes 3 methods:
 *
 * Start method at startup
 * loop method that is called over and over until one of either quit() or
 * forceQuit() are called end method when quit() is called
 *
 * subclasses must have a public, implicit constructor
 *
 * @author aliu
 *
 */
public abstract class LoopRunner extends Runner {

  private boolean run;

  public LoopRunner() { run = true; }

  /**
   * Create an array of specified length, which will eventually become an Object
   * array of string objects.
   * @param arrayLength length of array
   */
  public static void launch(int arrayLength) {
    Runner.launch(new String[arrayLength]);
  }

  @Override
  public final void start(String... args) throws Exception {
    atStart();
    while (run) {
      loop();
    }
    atEnd();
  }

  /**
   * This method is executed before entering the loop
   * @throws Exception generalized exception
   */
  public abstract void atStart() throws Exception;

  /**
   * This method is executed in the loop until the method quit() or forceQuit()
   * is called.
   * @throws Exception generalized exception
   */
  public abstract void loop() throws Exception;

  /**
   * This method is executed when the loop ends if quit() is called, but not if
   * forceQuit() is called.
   * @throws Exception generalized exception
   */
  public abstract void atEnd() throws Exception;

  /**
   * Checks if the loop is running
   * @return true if the loop is running
   */
  public final boolean isRunning() { return run; }

  /**
   * Quits the loop.
   */
  protected final void quit() { run = false; }

  /**
   * Quits the program. Skips over all methods.
   * @throws InterruptedException the exception that causes a full application
   *     quit.
   */
  protected final void forceQuit() throws InterruptedException { super.quit(); }
}
