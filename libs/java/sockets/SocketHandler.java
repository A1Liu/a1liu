package sockets;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.Serializable;
import java.net.Socket;
import java.util.LinkedList;

/**
 * This class represents a handler for individual clients. It establishes a
 * connection, then handles information transfer until it is told to disconnect
 * @author aliu
 *
 */
public class SocketHandler extends Thread {

  private Socket socket;
  private ObjectOutputStream out;
  private ObjectInputStream in;
  private volatile boolean running;
  private volatile StreamQueue<Serializable> outQueue;
  private volatile StreamQueue<Object> inQueue;

  private SocketHandler(Socket socket) {
    this.socket = socket;
    out = null;
    in = null;
    outQueue = new StreamQueue<Serializable>();
    inQueue = new StreamQueue<Object>();
    this.setPriority(MAX_PRIORITY - 2);
    running = false;
  }

  /**
   * Gets a RequestHandler instance and starts it
   * @param socket the socket to connect to
   * @return a RequestHandler instance
   */
  public static final SocketHandler getStart(Socket socket) {
    SocketHandler requestHandler = new SocketHandler(socket);
    requestHandler.start();
    return requestHandler;
  }

  /**
   * Gets a RequestHandler instance
   * @param socket the socket to connect to
   * @return a request handler instance
   */
  public static SocketHandler getInstance(Socket socket) {
    return new SocketHandler(socket);
  }

  @Override
  public final void run() {
    running = true;
    try {
      out = new ObjectOutputStream(
          new BufferedOutputStream(socket.getOutputStream()));
      in = new ObjectInputStream(
          new BufferedInputStream(socket.getInputStream()));
      runOverride();
    } catch (IOException e) {
      e.printStackTrace();
    } catch (ClassNotFoundException e) {
      e.printStackTrace();
    } catch (Exception e) {
      disconnect();
      throw new RuntimeException(e);
    }
    disconnect();
  }

  /**
   * Override this method to change the logic that this class uses to enqueue
   * and dequeue data into the queues
   */
  protected void runOverride() throws IOException, ClassNotFoundException {
    while (running) {
      while (running && !outQueue.isEmpty())
        getOutputStream().writeObject(outQueue.dequeue());
      while (running && getInputStream().read() > 0)
        inQueue.enqueue(getInputStream().readObject());
    }
  }

  /**
   * Writes a Serializable object to the stream
   * @param o the object to output
   */
  public synchronized final void write(Serializable o) { outQueue.enqueue(o); }

  /**
   * Reads an object from the stream
   * @return an object from the stream
   */
  public synchronized final Object readObject() {
    if (!inQueue.isEmpty())
      return inQueue.dequeue();
    else
      return null;
  }

  /**
   * Checks if this thread is running
   * @return true if running
   */
  public final boolean isRunning() { return running; }

  /**
   * disconnects from the socket
   */
  protected final void disconnect() {
    running = false;
    try {
      if (out != null)
        out.close();
      if (in != null)
        in.close();
      socket.close();
    } catch (IOException e) {
      e.printStackTrace();
    }
  }

  /**
   * gets the OutputStream
   * @return the OutputStream
   */
  protected synchronized ObjectOutputStream getOutputStream() { return out; }

  /**
   * gets the InputStream
   * @return the InputStream
   */
  protected synchronized ObjectInputStream getInputStream() { return in; }

  public class StreamQueue<E> {
    private volatile LinkedList<E> queue;
    StreamQueue() { queue = new LinkedList<E>(); }
    public void enqueue(E e) { queue.add(e); }
    public E dequeue() { return queue.removeFirst(); }
    public E peek() { return queue.getFirst(); }
    public boolean isEmpty() { return queue.isEmpty(); }
  }
}
