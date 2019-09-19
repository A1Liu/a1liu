package commands;

import java.util.Arrays;

/**
 * This represents a command that can be used to move to another part of the
 * tree
 * @author aliu
 *
 */
public final class SkipC extends ObjParamC<Commands> {

  private ComTreeNode node;

  public SkipC(Commands object, String... path) {
    super(object);
    node = this.getObject().getNode(path);
  }

  @Override
  public final void execute(Object... elist) {
    String[] in;
    if (elist.length == 0)
      in = new String[0];
    else {
      in = Arrays.copyOf(elist, elist.length, String[].class);
    }
    setOutput(getObject().input(node, in));
  }

  ComTreeNode getLocation() { return node; }
}
