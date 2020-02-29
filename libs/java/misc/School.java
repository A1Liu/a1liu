package misc;

import java.io.*;
import java.util.*;
import java.util.stream.*;

public final class School {

  private static final BufferedWriter out =
      new BufferedWriter(new OutputStreamWriter(System.out));
  private static final BufferedWriter err =
      new BufferedWriter(new OutputStreamWriter(System.err));
  private static final Scanner reader =
      new Scanner(new BufferedReader(new InputStreamReader(System.in)));

  private School() {}

  public static void main(String[] args) {
    serializeObject("hello/asdf", null);
    println(getCallsite());
  }

  @SuppressWarnings("unchecked")
  public static <T> ArrayList<T> listOf(T... elements) {
    ArrayList<T> list = new ArrayList<T>();
    for (T e : elements) {
      list.add(e);
    }
    return list;
  }

  public static String readFile(String path) {
    try {
      return new BufferedReader(new FileReader(path))
          .lines()
          .collect(Collectors.joining());
    } catch (IOException e) {
      throw new RuntimeException(e);
    }
  }

  public static StackTraceElement getCallsite() {
    StackTraceElement[] stack = Thread.currentThread().getStackTrace();
    if (stack.length == 0)
      return null;
    else if (stack.length == 1)
      return stack[0];
    else
      return stack[1];
  }

  public static void serializeObject(String filename, Serializable object) {
    FileOutputStream file;
    ObjectOutputStream out;
    try {
      try {
        file = new FileOutputStream(filename);
        out = new ObjectOutputStream(file);
      } catch (FileNotFoundException e) {
        err.write("Failure at " + getCallsite().toString() + ": \n  ");
        err.write(
            "File \"" + filename +
            "\" couldn't be found. Did you forget to make a directory?\n");
        err.flush();
        return;
      }
    } catch (IOException e) { // Something went really wrong
      throw new RuntimeException(e);
    }
    try {
      out.writeObject(object);
    } catch (NotSerializableException e) {
      try {
        err.write("Failure at " + getCallsite().toString() + ": \n  ");
        err.write(
            "Object=" + object.toString() +
            " could not be serialized (an object that it contains doesn't implement serializable)\n");
        err.flush();
      } catch (IOException ioe) { // something went really wrong
        throw new RuntimeException(ioe);
      }
    } catch (IOException e) {
      throw new RuntimeException(e);
    }
  }

  public static void serializeObjects(String filename,
                                      Serializable... objects) {
    FileOutputStream file;
    ObjectOutputStream out;
    try {
      try {
        file = new FileOutputStream(filename);
        out = new ObjectOutputStream(file);
      } catch (FileNotFoundException e) {
        err.write(
            "File \"" + filename +
            "\" couldn't be found. Did you forget to make a directory?\n");
        err.flush();
        return;
      }
    } catch (IOException e) { // Something went really wrong
      throw new RuntimeException(e);
    }
    int i = 0;
    try {
      for (; i < objects.length; i++) {
        out.writeObject(objects[i]);
      }
    } catch (NotSerializableException e) {
      try {
        err.write("Failure at " + getCallsite().toString() + ": \n  ");
        err.write(
            "Object=" + objects[i].toString() +
            " could not be serialized (an object that it contains doesn't implement serializable)\n");
        err.flush();
      } catch (IOException ioe) { // something went really wrong
        throw new RuntimeException(ioe);
      }
    } catch (IOException e) {
      throw new RuntimeException(e);
    }
  }

  public static void println(Object o) {
    try {
      out.write(o == null ? "null" : o.toString());
      out.write('\n');
      out.flush();
    } catch (IOException e) { // Something went really wrong
      throw new RuntimeException(e);
    }
  }

  public static String prompt(String prompt) {
    return reader.next() + reader.nextLine();
  }
}
