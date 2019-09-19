package sockets;

import java.io.IOException;
import java.net.ServerSocket;
import java.util.ArrayList;

/**
 * Handles incoming connections and passes them off to a RequestHandler, then
 * starts it up
 * @author Albert Liu
 *
 */
public abstract class ClientHandler extends Thread {

  private ServerSocket server;
  private int port;
  private volatile boolean running;
  private volatile ArrayList<RequestHandler> connections;

  protected ClientHandler(int port) {
    this.port = port;
    running = false;
    this.setPriority(MIN_PRIORITY);
    connections = new ArrayList<RequestHandler>();
  }

  @Override
  public void start() {
    try {
      server = new ServerSocket(port);
      super.start();
    } catch (IOException e) {
      e.printStackTrace();
    }
  }

  @Override
  public void run() {
    running = true;
    System.out.println("Listening for connections.");
    while (running) {
      try {
        RequestHandler requestHandler = getRequestHandler();
        requestHandler.setHandler(SocketHandler.getStart(server.accept()));
        new Thread(requestHandler).start();
        connections.add(requestHandler);
        System.out.println("Connection established!");
      } catch (IOException e) {
        System.out.println("Failed to connect. Retrying...");
      }
    }
  }

  /**
   * Gets a new RequestHandler instance
   * @param socket socket to connect the requestHandler to
   * @return a new RequestHandler instance
   */
  public abstract RequestHandler getRequestHandler();

  /**
   * Disconnects all connections
   */
  public void disconnectAll() {
    for (RequestHandler request : connections) {
      request.getHandler().disconnect();
      request.quit();
    }
    connections = new ArrayList<RequestHandler>();
  }

  /**
   * Go offline
   */
  public void offline() {
    this.disconnectAll();
    running = false;
    try {
      server.close();
    } catch (Exception e) {
    }
  }
}
