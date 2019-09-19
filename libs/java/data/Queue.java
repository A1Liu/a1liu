package data;

import java.util.Arrays;
import java.util.Collection;
import java.util.Iterator;
import java.util.NoSuchElementException;

/**
 * This class represents an implementation of the queue interface, which is a
 * first-in-first-out (FIFO) data storage system.
 * @author Alyer
 *
 * @param <T> The data type of the elements stored in the queue
 */
public class Queue<T> implements java.util.Queue<T> {

  private Node<T> front;
  private Node<T> back;
  private int size;

  public Queue() {
    front = null;
    back = null;
    size = 0;
  }

  @Override
  public int size() {
    return size;
  }

  @Override
  public boolean isEmpty() {
    return size == 0;
  }

  @Override
  public boolean contains(Object o) {
    Node<T> node = front;

    while (node.next != null) {
      if (node.data.equals(o))
        return true;
      node = node.next;
    }
    return node.data.equals(o);
  }

  @Override
  public Iterator<T> iterator() {
    return new QueueIterator<T>(front);
  }

  @Override
  public Object[] toArray() {
    Object[] a = new Object[size];
    Node<T> current = front;
    int index = 0;
    while (current != null) {
      a[index++] = current.data;
      current = current.next;
    }
    return a;
  }

  @SuppressWarnings("unchecked")
  @Override
  public <E> E[] toArray(E[] a) {
    Object[] array;
    try {
      array = (Object[])a;
    } catch (Exception e) {
      throw new ArrayStoreException();
    }
    if (a.length < size) {
      array = Arrays.copyOf(array, size);
    }
    Node<T> current = front;
    int index = 0;
    while (current != null) {
      array[index++] = current.data;
      current = current.next;
    }

    if (index < array.length)
      array[index] = null;
    try {
      return (E[])array;
    } catch (Exception e) {
      throw new ArrayStoreException();
    }
  }

  @Override
  public boolean remove(Object o) {
    return false;
  }

  @Override
  public boolean containsAll(Collection<?> c) {
    return false;
  }

  @Override
  public boolean addAll(Collection<? extends T> c) {
    Iterator<? extends T> iterator = c.iterator();
    while (iterator.hasNext()) {
      add(iterator.next());
    }
    return true;
  }

  @Override
  public boolean removeAll(Collection<?> c) {
    return false;
  }

  @Override
  public boolean retainAll(Collection<?> c) {
    return false;
  }

  @Override
  public synchronized void clear() {
    front = null;
    back = null;
  }

  @Override
  public synchronized boolean add(T e) {
    if (isEmpty()) {
      back = new Node<T>(e);
      front = back;
    } else {
      back.next = new Node<T>(e);
      back = back.next;
    }
    size++;
    return true;
  }

  @Override
  public boolean offer(T e) {
    return add(e);
  }

  @Override
  public T remove() {
    if (front == null)
      throw new NoSuchElementException();
    return poll();
  }

  @Override
  public synchronized T poll() {
    if (front == null)
      return null;
    T data = front.data;
    front = front.next;
    size--;
    if (front == null)
      back = null;
    return data;
  }

  @Override
  public T element() {
    try {
      return front.data;
    } catch (NullPointerException e) {
      throw new NoSuchElementException();
    }
  }

  @Override
  public T peek() {
    return front == null ? null : front.data;
  }

  private class Node<E> {

    Node<E> next;
    E data;

    Node(E data) {
      this.data = data;
      this.next = null;
    }
  }

  private class QueueIterator<E> implements Iterator<E> {

    private Node<E> current;

    QueueIterator(Node<E> front) { this.current = front; }

    @Override
    public boolean hasNext() {
      return current == null;
    }

    @Override
    public E next() {
      if (current == null) {
        throw new NoSuchElementException();
      } else {
        E data = current.data;
        current = current.next;
        return data;
      }
    }
  }
}
