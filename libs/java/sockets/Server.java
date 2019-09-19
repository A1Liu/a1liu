package sockets;

/**
 * The Server has 2 parts:
 *
 * Client Thread handling, and Server side threads.
 *
 * @author aliu
 *
 */
public abstract class Server extends Thread {

  ClientHandler clientHandler;

  protected Server(ClientHandler threadHandler) {
    this.clientHandler = threadHandler;
  }

  /**
   * Non-Client related run tasks.
   */
  public abstract void run();

  public synchronized final void goOnline() { clientHandler.start(); }

  public synchronized final void goOffline() {
    clientHandler.disconnectAll();
    try {
      clientHandler.offline();
    } catch (Exception e) {
    }
  }
}
