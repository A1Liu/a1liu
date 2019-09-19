package commands.simple;

import commands.Command;
import java.util.Hashtable;

/**
 * @author aliu
 *
 */
class SimpleCList {

  private SimpleComTree
      comTree; // This is the data structure that holds the command hierarchy.
  private Hashtable<Integer, Command> coms;
  private int count;

  SimpleCList() {
    comTree = new SimpleComTree();
    coms = new Hashtable<Integer, Command>();
    count = 0;
  }

  /**
   * adds an executable command to the command tree
   * @param path
   * @param c
   */
  void addCommand(String[] path, Command command) {
    if (command == null)
      throw new RuntimeException("The command object cannot be null.");
    while (!coms.containsKey(++count)) {
    }
    comTree.addPath(path, count);
    coms.put(count, command);
  }

  void addCommand(Integer label, Command command) {
    if (command == null)
      throw new RuntimeException("The command object cannot be null.");
    if (label.intValue() < 0)
      throw new IllegalArgumentException("Cannot have a negative ID.");
    coms.put(label, command);
  }

  /**
   * adds functionality to a point on the command tree. Only adds to points that
   * already exist.
   * @param label
   * @param command
   */
  void setCommand(Integer label, Command command) {
    if (command == null)
      throw new RuntimeException("The command object cannot be null.");
    coms.replace(label, command);
  }

  public String toString() {
    return comTree.toString().replaceFirst("\\n", "");
  }

  /**
   * Get the command associated with the integer id
   * @param id integer id
   * @return command associated with the id
   */
  Command get(Integer id) { return coms.get(id); }

  /**
   * Getter for the Command tree
   * @return the command tree
   */
  SimpleComTree getTree() { return comTree; }
}
