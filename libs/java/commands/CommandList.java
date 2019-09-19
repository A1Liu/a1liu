package commands;

import static commands.Util.*;

import java.util.Hashtable;

// clang-format off
/**
 * Takes formatted command graph, and creates a graph of commands
 *
 * Format:
 *
 *<pre>
 * 	Command
 * 		SubCommand:2; Words after the semicolon are considered help text, and can be viewed by the user using the 'help' command.
 * 		SubCommand2:4; The integer after the colon specifies a key to be used when creating command objects using setCommand().
 * 		SubCommand3:4; The integer isn't necessary, but it helps make assigning commands to end-points in the tree easier.
 * 			SubSubCommand:-3; the integer can't be negative. This will throw a CommandConfiguration exception
 * 			SubSubCommand:2; Writing the same command name for 2 commands that are siblings in the tree results in the combining of both. The help text and integer ID of the last one are used
 * 			SubSubCommand:1; But the command below won't overwrite the help text, because it doesn't have helpText.
 * 			SubSubCommand
 * 			SubSubCommand; However, if you include a semicolon, it will overwrite the help text, like the one below
 *			SubSubCommand;
 * 			SubSubCommand:3; Even though the -3 is overridden by 2 in the above commands, -3 is checked first, so an exception will be thrown before the interpreter reaches 2
 * 	help; adding the help command here overrides the default help command
 * 	Null; typing null anywhere in the tree creates a null node. This can't be accessed by the user, so use these to make hidden commands accessible only by code
 * </pre>
 * @author aliu
 *
 */
class CommandList {
  // clang-format on

  private ComTree
      comTree; // This is the data structure that holds the command hierarchy.
  private Hashtable<Integer, Command> coms;
  private int count;

  CommandList(String[] graph) { this.addGraph(graph); }

  CommandList() {
    comTree = new ComTree();
    coms = new Hashtable<Integer, Command>();
    coms.put(-1, new NullC());
    count = 0;
  }

  /**
   * Begins the recursion to create the command tree based off of a formatted
   * String array
   * @param commands the array of strings that represents the command tree
   */
  void addGraph(String[] commands) {
    for (int x = 0; x < commands.length; x++) {
      int y = commands[x].lastIndexOf('\t') + 1; // TODO Make this more robust
      commands[x] = y + commands[x].trim() + " ";
    }

    addGraph(comTree.getRoot(), commands, 0, commands.length - 1);
    addHelp(comTree.getRoot());
  }

  /**
   * Recursively creates a tree using a string array that represents the tree
   * @param node The parent node of this recursive call
   * @param commands the string array to take input from
   * @param startIndex The initial index of this recursive call
   * @param endIndex the stopping point of this recursive call
   */ //Maybe this needs to return a list of null entries so the exterior graph doesn't need to recursively add help commands
  private void addGraph(ComTreeNode node, String[] commands, int startIndex,
                        int endIndex) {
    int indent = Integer.parseInt(commands[startIndex].substring(
        0, 1)); // what level of the tree are we at?

    for (int x = startIndex; x <= endIndex;
         x++) { // loop through all of the lines in the array. X represents the
                // position the reader is at in the array.
      if (Integer.parseInt(commands[x].substring(0, 1)) ==
          indent) { // If the line we're reading is at the level we're at, then
                    // let's add it to the tree
        String[] commandParts = formatCommand(commands[x]);
        String command = commandParts[0];
        addCommand(node, commandParts);

        if (x < endIndex) { // If we're not at the end of this call's scope,
                            // then this could be a parent node
          if (Integer.parseInt(commands[x + 1].substring(0, 1)) >
              indent) { // If this node is a parent node, call recursion
            ComTreeNode parent =
                node.getChild(command); // create a reference to the parent node
            int begin =
                x + 1; // the call should begin right below the parent's line

            while (x < endIndex &&
                   Integer.parseInt(commands[x + 1].substring(0, 1)) > indent) {
              x++;
            } // And end at the end of the scope of the recursion, or when the
              // next item at this call's level is, whichever comes first.
            addGraph(parent, commands, begin, x); // enter recursion if
                                                  // necessary
          } else if (node.getChild(command).getID() == null) {
            node.getChild(command).setID(-1);
          }
        } else if (node.getChild(command).getID() == null)
          node.getChild(command).setID(-1);
      }
    }
    if (node.getName() == null)
      addHelp(node); // if the parent node we're looking at is a null, we should
                     // add a help menu
  }

  private String[] formatCommand(String raw) {
    String command = raw.substring(1).trim();
    String[] out = command.split("\\s*;\\s*", 2);
    if (out.length > 1) {
      out[1] = (out[1].trim().equals("") ? null : out[1].trim());
      out = Util.append(out[0].split(":", 2), out[1]);
    } else {
      out = out[0].split(":", 2);
    }
    out[0] = out[0].toLowerCase().replaceAll("\\s", "");
    if (out[0].equals("null") || out[0].equals(""))
      out[0] = null;
    return out;
  }

  private void addCommand(ComTreeNode parent, String[] command) {
    ComTreeNode node = new ComTreeNode(command[0]);
    if (command.length >= 3) { // in form name:ints - helptext
      if (isNumber(command[1])) {
        node.setID(Integer.parseInt(command[1]));
        addCommand(Integer.parseInt(command[1]), new NullC());
      }
      node.setHelp(command[2]);
    } else if (command.length == 2) {
      if (isNumber(command[1].trim())) {
        node.setID(Integer.parseInt(command[1].trim()));
        addCommand(Integer.parseInt(command[1].trim()), new NullC());
      } else {
        node.setHelp(command[1]);
      }
    }
    parent.addChild(node);
  }

  /**
   * adds an executable command to the command tree
   * @param path
   * @param c
   */
  void addCommand(String[] path, Command command) {
    if (command == null)
      throw new CommandConfigurationException(
          "The command object cannot be null.");
    while (!coms.containsKey(++count)) {
    }
    comTree.addPath(path, count);
    coms.put(count, command);
  }

  void addCommand(Integer label, Command command) {
    if (command == null)
      throw new CommandConfigurationException(
          "The command object cannot be null.");
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
      throw new CommandConfigurationException(
          "The command object cannot be null.");
    coms.replace(label, command);
  }

  /**
   * Adds a help command to the
   * @param parent
   */
  void addHelp(ComTreeNode parent) {
    if (!parent.containsChild("help")) {
      while (coms.containsKey(++count)) {
      }
      parent.addChild(
          "help", count,
          "This command gives helpful information. You can add command paths as arguments and it will give you help for a specific command.");
      coms.put(count, new HelpC(this, parent));
    }
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
  ComTree getTree() { return comTree; }
}
