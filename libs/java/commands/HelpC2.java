package commands;

/**
 * This class represents a command that outputs a guide to a command tree.
 * Deprecated version, code available until the new version is confirmed as
 * stable n stuff
 * @deprecated
 * @author aliu
 *
 */
public class HelpC2 implements Command {

  private ComTree commands;
  private String output;

  public HelpC2(ComTree commands) { this.commands = commands; }

  @Override
  public Object execute(String... elist) {
    execute((Object[])elist);
    return output;
  }

  @Override
  public void
  execute(Object... elist) { // Need to account for null... Maybe by having the
                             // constructor add in the help commands after the
                             // fact? Yes. Adding to all the null branches as
                             // well, with prepended null entries.
    output = "";
    String[] path = (String[])elist;
    boolean done = false;
    boolean listSubs = false;
    ComTreeNode current = commands.getRoot();
    for (String element : path) {
      if (!done) { // Traverses down the tree until it can't anymore. Note that
                   // a single wrong name will cause the help method to stop and
                   // print out an error message.
        if (current.containsChild(element))
          current = current.getChild(element);
        else if (element.endsWith("...") &&
                 current.containsChild(element.replace("...", ""))) {
          current = current.getChild(element.replace("...", ""));
          listSubs = true;
          done = true;
        } else if (element.equals("...")) {
          listSubs = true;
          done = true;
        } else {
          if (current == commands.getRoot()) {
            output += String.format(
                "NOTE: '%s' is not a valid command. For a list of valid commands and their explanations, type 'help'.%n",
                element);
          } else {
            output +=
                String.format("NOTE: '%s' is not a valid subcommand of '%s'.%n",
                              element, current.getName());
          }
        }
      } else {
        done = true;
      }
    }

    if (current == commands.getRoot()) { // If there were no parameters given
      System.out.println("Command List: ");
      for (ComTreeNode node : current.getChildren()) {
        String name = node.getName();
        String help = node.getHelp() == null
                          ? "'" + node.getName() + "' command."
                          : node.getHelp();
        output += String.format("  %8s %s%n", name + ":", help);
      }
    } else if (!listSubs) { // if the parameters were given but the user didn't
                            // ask for subcommands.
      String name = current.getName();
      String help = current.getHelp() == null
                        ? "'" + current.getName() + "' command."
                        : current.getHelp();
      output += String.format("%s %s%n", name + ":", help);
      output += String.format(
          "Type '...' at the end of the last command to get a list of available subcommands, along with help for each.%n");
    } else { // if the parameters were given with a '...' at the end, which
             // means that subcommands should also be outputted
      if (current.getChildren().size() == 0) {
        output += String.format("'%s' doesn't have any subcommands.",
                                current.getName());
      }

      output += String.format("Subcommands of'%s': %n", current.getName());
      for (ComTreeNode node : current.getChildren()) {
        String name = node.getName();
        String help = node.getHelp() == null
                          ? "'" + node.getName() + "' command."
                          : node.getHelp();
        output += String.format("  %8s %s%n", name + ":", help);
      }
    }
  }
}
