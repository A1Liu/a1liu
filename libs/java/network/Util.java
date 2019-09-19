package network;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.NoSuchElementException;

public class Util {

  /**
   * checks if a string is an integer
   * @param in string to test
   * @return true if the string can be parsed to an integer
   */
  public static boolean isNumber(String in) {
    try {
      Integer.parseInt(in);
    } catch (NumberFormatException e) {
      return false;
    }
    return true;
  }

  /**
   * writes to a document at the path specified
   * @param outPath path of the document to write to
   * @param strings the strings to write
   * @throws IOException If there's a problem writing to the file
   */
  public static void writeFile(String outPath, String... strings)
      throws IOException {
    BufferedWriter writer = new BufferedWriter(new FileWriter(outPath));
    for (int x = 0; x < strings.length; x++) {
      writer.write(strings[x]);
      writer.newLine();
    }
    writer.close();
  }

  /**
   * Reads the file that is given and creates a list from it
   * @param input name of file to be read
   * @throws IOException Throws an exception if there's a problem reading the
   *     file
   */
  public static ArrayList<String> readFile(String input) throws IOException {

    BufferedReader reader = new BufferedReader(new FileReader(input));
    ArrayList<String> output = new ArrayList<String>();

    String inputString = reader.readLine();
    while (inputString != null) {
      output.add(inputString);
      inputString = reader.readLine();
    }
    reader.close();
    return output;
  }
}

/**
 * This class represents a reference-based implementation of the Queue interface
 * @author Alyer
 *
 * @param <T> The data type of the elements being held in the queue
 */
class LinkedQueue<T> {

  private QueueNode<T> front;
  private QueueNode<T> back;

  public LinkedQueue() {
    front = null;
    back = null;
  }

  /**
   * Add an element to the queue
   * @param t the element to add to the queue
   */
  public void enqueue(T t) {
    if (isEmpty()) {
      front = new QueueNode<T>(t, null);
      back = front;
    } else {
      back.setNext(new QueueNode<T>(t, null));
      back = back.getNext();
    }
  }

  /**
   * Check what the first element of the queue is
   * @return The first element
   * @throws NoSuchElementException if there is no first element
   */
  public T front() throws NoSuchElementException {
    if (!this.isEmpty())
      return front.getData();
    throw new NoSuchElementException("Queue is Empty!");
  }

  /**
   * Takes the least recently placed item out of the queue
   * @return The element that was just removed from the queue
   * @throws NoSuchElementException if there is no element to remove
   */
  public T dequeue() throws NoSuchElementException {
    if (!this.isEmpty()) {
      T data = front.getData();
      front = front.getNext();
      if (front == null)
        back = null;
      return data;
    }
    throw new NoSuchElementException("Queue is Empty!");
  }

  /**
   * Checks whether the queue is empty
   * @return true if the queue is empty
   */
  public boolean isEmpty() { return back == null; }
}

class QueueNode<T> {

  private T data;
  private QueueNode<T> next;

  public QueueNode(T t) { this(t, null); }

  public QueueNode(T t, QueueNode<T> n) {
    data = t;
    next = n;
  }

  /**
   * getter for data
   * @return the data
   */
  public T getData() { return data; }

  /**
   * setter for data
   * @param data the data to set
   */
  public void setData(T data) { this.data = data; }

  /**
   * getter for next node
   * @return the next
   */
  public QueueNode<T> getNext() { return next; }

  /**
   * setter for next node
   * @param next the next to set
   */
  public void setNext(QueueNode<T> next) { this.next = next; }
}
