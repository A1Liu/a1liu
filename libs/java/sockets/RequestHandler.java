package sockets;

/**
 * Handles requests from the client. You don't need to start the SocketHandler
 * -- that's done at startup by the ClientHandler
 * @author Albert Liu
 *
 */
public interface RequestHandler extends Runnable {

  /**
   * Getter for the SocketHandler of this RequestHandler
   * @return the socketHandler
   */
  public SocketHandler getHandler();

  /**
   * Setter for the SocketHandler of this RequestHandler
   * @param socketHandler the socketHandler to set
   */
  public void setHandler(SocketHandler socketHandler);

  /**
   * Quits the RequestHandler
   */
  public void quit();
}
