package commands;

/**
 * This is an exception that occurs when the command tree hasn't been setup
 * properly.
 * @author aliu
 *
 */
public class CommandConfigurationException extends RuntimeException {

  /**
   *
   */
  private static final long serialVersionUID = 1L;

  /**
   * Constructs a CommandError with the given detail message.
   * @param message The detail message of the CommandError.
   */
  public CommandConfigurationException(String message) { super(message); }

  /**
   * Constructs a CommandError with the given root cause.
   * @param cause The root cause of the CommandError.
   */
  public CommandConfigurationException(Throwable cause) { super(cause); }

  /**
   * Constructs a CommandError with the given detail message and root cause.
   * @param message The detail message of the CommandError.
   * @param cause The root cause of the CommandError.
   */
  public CommandConfigurationException(String message, Throwable cause) {
    super(message, cause);
  }
}
