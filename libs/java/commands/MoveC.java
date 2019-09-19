package commands;

/**
 *
 * @author aliu
 *
 */
public class MoveC implements Command {

  private ComTreeNode node;
  private Commands commands;

  public MoveC(Commands commands, String... path) {
    this.commands = commands;
    node = commands.getNode(path);
  }

  @Override
  public void execute(Object... elist) {
    commands.setCurrentRoot(node);
  }
}
