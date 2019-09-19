package runner;

/**
 * Runner class. Doesn't help much for most stuff, except maybe if you wanted to
 * run multiple separate things. <br><br> Subclasses must have a public,
 * implicit constructor.
 * @author aliu
 *
 */
public abstract class Runner {

  public Runner() {}

  /**
   * Launches subclasses of Runner.
   * @param args arguments passed to the program at startup
   */
  public static void launch(String... args) {
    // Figure out the right class to call
    StackTraceElement[] cause = Thread.currentThread().getStackTrace();
    boolean foundThisMethod = false;
    String callingClassName = null;
    for (StackTraceElement se : cause) {
      // Skip entries until we get to the entry for this class
      String className = se.getClassName();
      String methodName = se.getMethodName();
      if (foundThisMethod) {
        callingClassName = className;
        break;
      } else if (Runner.class.getName().equals(className) &&
                 "launch".equals(methodName)) {

        foundThisMethod = true;
      }
    }
    if (callingClassName == null) {
      throw new RuntimeException("Error: unable to determine Runner class");
    }
    try {
      @SuppressWarnings("rawtypes")
      Class theClass =
          Class.forName(callingClassName, false,
                        Thread.currentThread().getContextClassLoader());
      if (Runner.class.isAssignableFrom(theClass)) {
        Runner runner = (Runner)Class.forName(theClass.getName()).newInstance();
        try {
          runner.start(args);
        } catch (InterruptedException i) {
          return;
        }
      } else {
        throw new RuntimeException(
            "Error: " + theClass +
            " is not a subclass of abstract class Runner");
      }
    } catch (RuntimeException ex) {
      throw ex;
    } catch (Exception ex) {
      throw new RuntimeException(ex);
    }
  }

  /**
   * Method that runs at startup.
   * @param args arguments passed to runner at startup
   * @throws Exception generalized exception
   */
  public abstract void start(String... args) throws Exception;

  /**
   * Quits the runner, skipping over the rest of code in the runner.
   * @throws InterruptedException the exception thrown to kill the runner
   */
  protected void quit() throws InterruptedException {
    throw new InterruptedException();
  }
}
