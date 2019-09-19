package commands;

import java.util.ArrayList;
import java.util.Arrays;

/**
 *
 * Takes inputs and traverses command graph using them.
 * TODO Reformat this package to be prettier
 * @author aliu
 *
 */
public class Commands {

  private CommandList comList;
  private String comPath;
  private ComTreeNode currentRoot;

  public Commands(CommandList comList) {
    this.comList = comList;
    comPath = "";
    currentRoot = comList.getTree().getRoot();
  }

  public Commands() { this(new CommandList()); }

  /**
   * Takes input string and parses it into a String array, then hands it to
   * another input method to traverse the tree.
   * @param in input string
   * @return Object that is output from the relevant command
   */
  public Object inputSimple(String in) {
    return input(in.trim().split("\\s+"));
  }

  /**
   * Takes input string and parses it into a String array, then hands it to
   * another input method to traverse the tree.
   * @param in input string
   * @return Object that is output from the relevant command
   */
  public final Object input(String in) {
    comPath = "";
    return input(convertString(in));
  }

  /**
   * takes an input and executes a command based off of it. Should traverse as
   * far as it can down the command tree and then take the rest of the input as
   * parameters
   * @param in the input string to take
   */
  public final Object input(
      String[] in) { // TODO Need to account for 'null' branch. Also need to
                     // create new help commands that also account for null.
    return input(currentRoot, in);
  }

  final Object input(ComTreeNode root, String[] in) {
    try {
      int counter = 0;
      ComTreeNode current = root;
      root.getChildren();
      while (counter < in.length && current.containsChild(in[counter])) {
        current = current.getChild(in[counter]);
        comPath += current.getName() + " ";
        counter++;
      }
      if (current == currentRoot) {
        throw new CommandException("That's not a valid command!");
      } else if (current.getID() == null && current.getChildren().size() != 0) {
        comPath = comPath.trim();
        if (counter < in.length) {
          throw new CommandException("'" + in[counter] +
                                     "' is not a recognized subcommand of " +
                                     comPath);
        } else {
          throw new CommandException(
              "'" + comPath +
              "' is not a complete command. Please pass more parameters.");
        }
      } else {
        return comList.get(current.getID())
            .execute(Arrays.copyOfRange(in, counter, in.length));
      }
    } catch (Exception e) {
      if (e instanceof CommandException)
        throw e;
      else
        throw new CommandException(e.getMessage(), e);
    }
  }

  /**
   * Converts a command string into a usable String array
   * @param in
   * @return
   */
  public final static String[] convertString(String in) {
    in = in.trim();
    int past = 0;
    int current = 0;
    boolean inQuotes = false;
    char quote = ' ';
    ArrayList<String> input = new ArrayList<String>();
    while (past < in.length()) {
      if (current < in.length()) {
        if (inQuotes) {
          if (in.charAt(current) == quote) {
            input.add(in.substring(past, current));
            past = current + 1;
            inQuotes = false;
          }
        } else {
          if ((in.charAt(current) == '"' || in.charAt(current) == '\'')) {
            if (past == current) {
              inQuotes = true;
              quote = in.charAt(current);
              past = current + 1;
            } else {
              input.add(in.substring(past, current));
              past = current + 1;
            }
          } else if (in.charAt(current) == ' ') {
            if (current == past) {
              past = current + 1;
            } else {
              input.add(in.substring(past, current));
              past = current + 1;
            }
          }
        }
      } else {
        input.add(in.substring(past, current));
        past = current;
      }
      current++;
    }
    return input.toArray(new String[0]);
  }

  ComTreeNode getNode(String... in) {
    int counter = 0;
    ComTreeNode current = comList.getTree().getRoot();
    while (counter < in.length && current.containsChild(in[counter])) {
      current = current.getChild(in[counter]);
      counter++;
    }
    return current;
  }

  public MoveC getMove(String... path) { return new MoveC(this, path); }

  public SkipC getSkip(String... path) { return new SkipC(this, path); }

  /**
   * Creates a command tree from a formatted String array
   * @param commands the array of strings that represents the command tree
   */
  public void addGraph(String[] commands) { comList.addGraph(commands); }

  /**
   * adds functionality to a point on the command tree. Only adds to points that
   * already exist.
   * @param label
   * @param command
   */
  public void setCommand(Integer label, Command command) {
    comList.setCommand(label, command);
  }

  /**
   * adds an executable command to the command tree
   * @param path
   * @param c
   */
  public void addCommand(String[] path, Command command) {
    comList.addCommand(path, command);
  }

  /**
   * Returns a command. Use primarily when a command tree isn't being used.
   * @param label integer identifier of command
   * @return the command
   */
  protected Command getCommand(Integer label) { return comList.get(label); }

  /**
   *  Maps a command to an integer label without checking whether it's
   * accessible to the command tree. Use this when a terminal isn't being used.
   * @param label integer label of command
   * @param command command object
   */
  protected void addCommand(Integer label, Command command) {
    comList.addCommand(label, command);
  }

  /**
   * Getter for command list
   * @return the command list
   */
  CommandList getCommandList() { return comList; }

  /**
   * Setter for the current root
   * @param root root node of the commands
   */
  void setCurrentRoot(ComTreeNode root) { currentRoot = root; }

  /**
   * Outputs the annotated structure of the command tree. Does not include help
   * messages.
   */
  public String toString() { return comList.toString(); }
}
