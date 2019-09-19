package runner;

import java.time.DayOfWeek;
import java.time.LocalDateTime;

/**
 *
 * Class that represents a script that can be executed. Contains helper methods
 * that might be useful for writing a script.
 *
 * @author aliu
 *
 */
public abstract class Script implements Runnable {

  private final double NANO_CONVERSION = 1000000000.0;
  private long startTime;
  private long endStartup;
  private long endScript;
  private long endQuit;
  public static final int SUNDAY = 0;
  public static final int MONDAY = 1;
  public static final int TUESDAY = 2;
  public static final int WEDNESDAY = 3;
  public static final int THURSDAY = 4;
  public static final int FRIDAY = 5;
  public static final int SATURDAY = 6;

  public Script() {}

  /**
   * Creates a Thread object to run this script on
   * @return a thread object
   */
  public final Thread getThread() { return new Thread(this); }

  /**
   * Run this script
   */
  public final void run() {
    try {
      startTime = System.nanoTime();
      startup();
      endStartup = System.nanoTime();
      runScript();
      endScript = System.nanoTime();
      onQuit();
      endQuit = System.nanoTime();
      ;
      System.out.printf("---------- SCRIPT RUNTIME -----------%n"
                            + "  Startup Duration: %f seconds%n"
                            + "   Script Duration: %f seconds%n"
                            + " Shutdown Duration: %f seconds%n",
                        (endStartup - startTime) / NANO_CONVERSION,
                        (endScript - endStartup) / NANO_CONVERSION,
                        (endQuit - endScript) / NANO_CONVERSION);
    } catch (Exception e) {
      e.printStackTrace();
      onQuit();
    }
  }

  /**
   * Actions that the script needs to perform at startup
   * @throws Exception
   */
  protected abstract void startup() throws Exception;

  /**
   * Actions that the script should perform
   */
  protected abstract void runScript() throws Exception;

  /**
   * Gets the hour of the day, 24-hour clock style (from 0-23)
   * @return the hour of the day
   */
  public static int getHour() { return LocalDateTime.now().getHour(); }

  /**
   * Gets the minutes since the last hour began field i.e. 59 in '11:59'
   * @return the minutes field for this hour
   */
  public static int getMinute() { return LocalDateTime.now().getMinute(); }

  /**
   * Gets the time in the military time format, starting with 0000 at midnight
   * and ending with 2359 at 11:59 pm
   * @return military time
   */
  public static int getMilitaryTime() { return 100 * getHour() + getMinute(); }

  /**
   * Returns an integer representing the day of the week, where 0 is Sunday and
   * 6 is Saturday
   * @return integer representing the day of the week
   */
  public static int dayOfWeek() {
    return LocalDateTime.now().getDayOfWeek().compareTo(DayOfWeek.SUNDAY);
  }

  /**
   * Prints to System.out.println
   */
  public static void sysp() { System.out.println(); }

  /**
   * Prints to System.out.println
   * @param o object to print
   */
  public static void sysp(Object o) {
    if (o != null)
      System.out.println(o.toString());
    else
      System.out.println("[null]");
  }

  /**
   * Actions that the script should perform on shutdown
   */
  protected abstract void onQuit();
}
