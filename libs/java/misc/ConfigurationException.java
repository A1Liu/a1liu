package misc;

public class ConfigurationException extends RuntimeException {

  /**
   *
   */
  private static final long serialVersionUID = 1L;

  /**
   * Constructs a ConfigurationException with the given detail message.
   * @param message The detail message of the ConfigurationException.
   */
  public ConfigurationException(String message) { super(message); }

  /**
   * Constructs a ConfigurationException with the given root cause.
   * @param cause The root cause of the ConfigurationException.
   */
  public ConfigurationException(Throwable cause) { super(cause); }

  /**
   * Constructs a ConfigurationException with the given detail message and root
   * cause.
   * @param message The detail message of the ConfigurationException.
   * @param cause The root cause of the ConfigurationException.
   */
  public ConfigurationException(String message, Throwable cause) {
    super(message, cause);
  }
}
