package commands;

/**
 * The standard interface for executable commands. This interface is easiest to
 * use if the executable takes mainly strings as parameters.
 * @author aliu
 *
 */
public interface Command {

  /**
   * Behind the scenes method to take parameters. Used by built-in
   * implementations of this interface to handle things like error trapping.
   * @param elist list of parameters that the user has inputted
   */
  default Object execute(String... elist) {
    execute((Object[])elist);
    return null;
  }

  /**
   * The default method that all command objects implement. This is what the
   * object will execute in most cases.
   * @param elist list of elements for the method to take as parameters
   */
  public void execute(Object... elist);
}
