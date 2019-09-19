package commands;

/**
 * This class represents an empty command -- i.e. a 'null' entry in the command
 * tree's hash table.
 * @author aliu
 *
 */
class NullC implements Command {

  public NullC() {}

  @Override
  public void execute(Object... elist) {
    throw new CommandConfigurationException(
        "The command doesn't have an associated executable task.");
  }
}
