package commands;

/**
 * This is an exception that wraps around all exceptions from commands.
 * @author aliu
 *
 */
public class CommandException extends RuntimeException {

  /**
   *
   */
  private static final long serialVersionUID = 1L;

  /**
   * Constructs a CommandError with the given detail message.
   * @param message The detail message of the CommandError.
   */
  public CommandException(String message) { super(message); }

  /**
   * Constructs a CommandError with the given root cause.
   * @param cause The root cause of the CommandError.
   */
  public CommandException(Throwable cause) { super(cause); }

  /**
   * Constructs a CommandError with the given detail message and root cause.
   * @param message The detail message of the CommandError.
   * @param cause The root cause of the CommandError.
   */
  public CommandException(String message, Throwable cause) {
    super(message, cause);
  }

  public String toString() { return this.getMessage(); }
}
