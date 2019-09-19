package debug;

import java.io.*;
import java.util.*;
import java.util.function.Function;

/**
 * This class holds static utility methods for debugging. All dependencies are
 * public api
 *
 * @author aliu
 *
 */
public final class DebugMethods {

  private static PrintStream PRINT_STREAM;
  private static double DEFAULT_SLEEP_TIME;
  private static BufferedReader READER;
  private static Scanner SCANNER;
  private static String filePath;
  private static Timer
      sysTimer; // TODO add counters to do more runtime analysis i.e. timers
                // have a .count() method or something like that, and the count
                // can be outputted (if it is used)
  private static Timer[] timers; // Make into a hashtable?

  static {
    filePath = null;
    timers = null;
    setInputStream(System.in);
    setPrintStream(System.out);
    DEFAULT_SLEEP_TIME = 1;
  }

  private DebugMethods() {}

  /*----Print Utilities---*/

  /**
   * Prints an array object using {@link DebugMethods#print}
   * @param array array to print
   */
  public static <T> void printArray(T[] array) {
    simplePrint(arrayToList(array).toString());
  }

  /**
   * Prints an array object using {@link DebugMethods#print}
   * @param array array to print
   */
  public static void printArray(int[] array) {
    simplePrint(arrayToList(array).toString());
  }

  /**
   * Prints an array object using {@link DebugMethods#print}
   * @param array array to print
   */
  public static void printArray(char[] array) {
    simplePrint(arrayToList(array).toString());
  }

  /**
   * Prints an array object using {@link DebugMethods#print}
   * @param array array to print
   */
  public static void printArray(short[] array) {
    simplePrint(arrayToList(array).toString());
  }

  /**
   * Prints an array object using {@link DebugMethods#print}
   * @param array array to print
   */
  public static void printArray(long[] array) {
    simplePrint(arrayToList(array).toString());
  }

  /**
   * Prints an array object using {@link DebugMethods#print}
   * @param array array to print
   */
  public static void printArray(byte[] array) {
    simplePrint(arrayToList(array).toString());
  }

  /**
   * Prints an array object using {@link DebugMethods#print}
   * @param array array to print
   */
  public static void printArray(double[] array) {
    simplePrint(arrayToList(array).toString());
  }

  /**
   * Prints an array object using {@link DebugMethods#print}
   * @param array array to print
   */
  public static void printArray(float[] array) {
    simplePrint(arrayToList(array).toString());
  }

  /**
   * Prints an array object using {@link DebugMethods#print}
   * @param array array to print
   */
  public static void printArray(boolean[] array) {
    simplePrint(arrayToList(array).toString());
  }

  /**
   * System.out.println
   */
  public static void simplePrint() { PRINT_STREAM.println(); }

  /**
   * Prints the toString of the object, or 'null' if the object is a null
   * @param o object to print
   */
  public static void simplePrint(Object o) {
    if (o == null)
      PRINT_STREAM.println("null");
    else
      PRINT_STREAM.println(o.toString());
  }

  /**
   * Prints to the print stream with a formatted string
   * @param format format of the string to print
   * @param args arguments
   */
  public static void simplePrintf(String format, Object... args) {
    PRINT_STREAM.printf(format, args);
  }

  /**
   * Prints a marker statement to the system output
   */
  public static void print() {
    PRINT_STREAM.printf("Print statement called at %s", stackString());
  }

  /**
   * Prints an object, the object's class, and the location of the print
   * statement
   * @param o object to print
   */
  public static void print(Object o) {
    String output;
    String outputClass;
    if (o == null) {
      output = null;

      outputClass = "unknown class: object is null";
    } else {
      output = o.toString();
      outputClass = output.getClass().toString();
    }
    PRINT_STREAM.printf(
        "Object class: <%s>%nObject value: [%s]%nPrint Called at: %s",
        outputClass, output, stackString()); // prints out the location of where
                                             // this statement was called
  }

  /**
   * Returns the stack trace element associated with this line
   * @return a stack trace element
   */
  public static String line() { return stackString(); }

  /*----File Utilities---*/

  /**
   * Sets the file path of the file to store information in
   *@param file file path of file to store stuff in
   */
  public static void setFilePath(String file) { filePath = file; }

  /**
   * writes the tostring form of an object to the file specified by {@link
   * DebugMethods#setFilePath(String)}
   * @param o object to write
   */
  public static void writeString(Object o) {
    if (o == null)
      write(null);
    else
      write(o.toString());
  }

  /**
   * Writes information of an object to a file specified by {@link
   * DebugMethods#setFilePath(String)}
   * @param obj object to store
   */
  public static <T extends Serializable> void write(T obj) {
    try {
      ObjectOutputStream stream =
          new ObjectOutputStream(new FileOutputStream(new File(filePath)));
      stream.writeObject(obj);
      stream.flush();
      stream.close();
    } catch (IOException e) {
      e.printStackTrace();
    }
  }

  /**
   * Reads information of an object from a file specified by {@link
   * DebugMethods#setFilePath(String)}
   * @return object from file
   */
  public static Object read() {
    try {
      ObjectInputStream stream =
          new ObjectInputStream(new FileInputStream(new File(filePath)));
      Object o = stream.readObject();
      stream.close();
      return o;
    } catch (IOException | ClassNotFoundException e) {
      e.printStackTrace();
      return null;
    }
  }

  /*----Method Utilities---*/

  /**
   * Catches all exceptions for a function
   * @param function function to catch exceptions for
   * @param input input to give to function
   * @return function's output, or null if an exception was thrown
   */
  public static <I, O> O catchAll(Function<I, O> function, I input) {
    try {
      return function.apply(input);
    } catch (Exception e) {
      e.printStackTrace();
      return null;
    }
  }

  /*----Input Utilities---*/

  /**
   * Gets input from System.in and returns it
   * @return String that was typed into command line, or null if there was an
   *     IOException
   */
  public static String getSystemInput() {
    try {
      return READER.readLine();
    } catch (IOException e) {
      e.printStackTrace();
      return null;
    }
  }

  /**
   * Gets a buffered reader of System.in
   * @return a BufferedReader object
   */
  public static BufferedReader getReader() { return READER; }

  /**
   * Gets a scanner of System.in
   * @return a Scanner object
   */
  public static Scanner getScanner() { return SCANNER; }

  /*----Timer Utilities---*/

  /**
   * Timer object
   * @author aliu
   *
   */
  private static class Timer {
    private final long startTime;
    private long stopTime;
    private StackTraceElement beginTimerLoc;
    private StackTraceElement endTimerLoc;
    Timer() { this(System.nanoTime()); }
    Timer(long startTime) {
      this.startTime = startTime;
      this.beginTimerLoc = stack(6);
      this.endTimerLoc = null;
    }

    public long stopTimer() { // Add method for longer times
      if (endTimerLoc == null) {
        stopTime = System.nanoTime();
        endTimerLoc = stack(5);
      } else {
        return this.timeSinceStart();
      }
      PRINT_STREAM.printf(
          "        Timer duration: %f s%n Timer start called at: %s%n  Timer stop called at: %s%n",
          (stopTime - startTime) / 1000000000.0, beginTimerLoc.toString(),
          endTimerLoc.toString()); // prints out the location of where this
                                   // statement was called
      return stopTime;
    }

    public long timeSinceStart() {
      long time = System.nanoTime() - startTime;
      PRINT_STREAM.printf(
          "Time since timer start: %f s%n Timer start called at: %s%n        Time called at: %s%n",
          time / 1000000000.0, beginTimerLoc.toString(),
          stackString(4).contains("stopTimer") ? stackString(6)
                                               : stackString(5));
      return time;
    }

    public boolean isRunning() { return endTimerLoc == null; }
  }

  /**
   * Exception for the timer
   * @author aliu
   *
   */
  static class TimerException extends RuntimeException {
    private static final long serialVersionUID = 1L;
    /**
     * Constructor for timer exception that adds message
     * @param message the message for the exception
     */
    public TimerException(String message) { super(message); }
  }

  /**
   * Sleeps for the default sleep time, which can be changed using
   * setDefaultSleep
   */
  public static void sleep() { sleep(DEFAULT_SLEEP_TIME); }

  /**
   * Thread sleeps for a certain amount of time. If negative number is given,
   * Default sleep time is used instead
   * @param seconds seconds to sleep
   */
  public static void sleep(int seconds) {
    if (seconds < 0)
      seconds = (int)DEFAULT_SLEEP_TIME;
    try {
      Thread.sleep(seconds * 1000);
    } catch (InterruptedException i) {
      i.printStackTrace();
    }
  }

  /**
   * Thread sleeps for a certain amount of time. If negative number is given,
   * Default sleep time is used instead
   * @param seconds seconds to sleep
   */
  public static void sleep(double seconds) {
    if (seconds < 0)
      seconds = DEFAULT_SLEEP_TIME;
    try {
      Thread.sleep((int)(seconds * 1000));
    } catch (InterruptedException i) {
      i.printStackTrace();
    }
  }

  /**
   * Start a timer instance
   */
  public static void timerStart() {
    if (sysTimer == null || !sysTimer.isRunning()) {
      sysTimer = new Timer();
    } else
      throw new TimerException("Can't start a timer that's still running!");
  }

  /**
   * Restart the timer instance
   */
  public static void timerRestart() { sysTimer = new Timer(); }

  /**
   * Stop the timer instance and print the time.
   * @return the nanoseconds since the timer started
   */
  public static long timerStop() {
    if (sysTimer == null)
      throw new TimerException("");
    else
      return sysTimer.stopTimer();
  }

  /**
   * Time since the timer started
   * @return nanoseconds since the timer started
   */
  public static long timeSinceStart() { return sysTimer.timeSinceStart(); }

  /**
   * starts a timer with the specified id
   * @param timerID the id of the timer
   */
  public static void timerStart(int timerID) {
    if (timers == null) {
      if (timerID >= 10) {
        timers = new Timer[timerID + 1];
      } else
        timers = new Timer[10];
    } else if (timerID >= timers.length) {
      timers = Arrays.copyOf(timers, (int)(timerID * 1.5));
    }
    if (timers[timerID] == null || !timers[timerID].isRunning()) {
      timers[timerID] = new Timer();
    } else
      throw new TimerException("Can't start a timer that's still running!");
  }

  /**
   * Stops a timer with the specified id
   * @param timerID id of the timer
   * @return the time in nanoseconds since the timer started
   */
  public static long timerStop(int timerID) {
    if (timerID >= timers.length || timers[timerID] == null)
      throw new TimerException("Invalid timer ID.");
    else
      return timers[timerID].stopTimer();
  }

  /**
   * time since specified timer started
   * @param timerID the id of the timer
   * @return the time in nanoseconds since the specified timer started
   */
  public static long timeSinceStart(int timerID) {
    if (timerID >= timers.length || timers[timerID] == null)
      throw new TimerException("Invalid timer ID.");
    else
      return timers[timerID].timeSinceStart();
  }

  /*--------debug settings----------*/

  /**
   * Changes the PrintStream that DebugMethods methods print to (System.out by
   * default)
   * @param printStream the new PrintStream to print to
   */
  public static void setPrintStream(PrintStream printStream) {
    if (printStream == null)
      throw new IllegalArgumentException("PrintStream cannot be null!");
    DebugMethods.PRINT_STREAM = printStream;
  }

  /**
   * Changes the InputStream that DebugMethods methods get input from (System.in
   * by default)
   * @param inputStream the new InputStream to get input from
   */
  public static void setInputStream(InputStream inputStream) {
    if (inputStream == null)
      throw new IllegalArgumentException("InputStream cannot be null!");
    SCANNER = new Scanner(inputStream);
    READER = new BufferedReader(new InputStreamReader(inputStream));
  }

  /**
   * Changes the default amount of time the method sleep() sleeps for. Negative
   * numbers are automatically changed to 1
   * @param seconds seconds to sleep
   */
  public static void setDefaultSleep(double seconds) {
    DEFAULT_SLEEP_TIME = seconds < 0 ? 1 : seconds;
  }

  /*--------private utility methods----------*/

  /**
   * turns an array to a list
   * @param array array to return
   * @return array as a list
   */
  private static <T> List<T> arrayToList(T[] array) {
    List<T> list = new ArrayList<T>();
    for (T item : array) {
      list.add(item);
    }
    return list;
  }

  private static Object arrayToList(int[] array) {
    List<Integer> list = new ArrayList<Integer>();
    for (int item : array) {
      list.add(item);
    }
    return list;
  }

  private static Object arrayToList(char[] array) {
    List<Character> list = new ArrayList<Character>();
    for (char item : array) {
      list.add(item);
    }
    return list;
  }

  private static Object arrayToList(long[] array) {
    List<Long> list = new ArrayList<Long>();
    for (long item : array) {
      list.add(item);
    }
    return list;
  }

  private static Object arrayToList(short[] array) {
    List<Short> list = new ArrayList<Short>();
    for (short item : array) {
      list.add(item);
    }
    return list;
  }

  private static Object arrayToList(double[] array) {
    List<Double> list = new ArrayList<Double>();
    for (double item : array) {
      list.add(item);
    }
    return list;
  }

  private static Object arrayToList(float[] array) {
    List<Float> list = new ArrayList<Float>();
    for (float item : array) {
      list.add(item);
    }
    return list;
  }

  private static Object arrayToList(boolean[] array) {
    List<Boolean> list = new ArrayList<Boolean>();
    for (boolean item : array) {
      list.add(item);
    }
    return list;
  }

  private static Object arrayToList(byte[] array) {
    List<Byte> list = new ArrayList<Byte>();
    for (byte item : array) {
      list.add(item);
    }
    return list;
  }

  /**
   * Utility method for printing the stack trace element associated with a
   * certain debugging method
   * @return the stack element of the method calling this method
   */
  private static String stackString() { return stackString(4); }

  /**
   * Utility method for printing the stack trace element associated with a
   * certain debugging method
   * @param depth integer describing the depth of this method call (default is
   *     3, add 1 for each additional call to reach this one)
   * @return the stack element of the utility method that started the stack
   */
  private static String stackString(int depth) {
    return stack(depth + 1).toString();
  }

  /**
   * Utility method for printing the stack trace element associated with a
   * certain debugging method
   * @param depth integer describing the depth of this method call (default is
   *     3, add 1 for each additional call to reach this one)
   * @return the stack element of the utility method that started the stack
   */
  private static StackTraceElement stack(int depth) {
    return Thread.currentThread().getStackTrace()[depth];
  }
}
