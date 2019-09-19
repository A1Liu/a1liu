package commands;

/**
 * This class is the lambda notation version of the PCommand Class. The two are
 * separated to preserve the abstract marker on execute(Object... elist) in
 * PCommand
 * @author aliu
 *
 */
public class LParamC extends ParamC {

  Command command;

  public LParamC(Command command, String... elist) {
    super(elist);
    if (command == null) {
      throw new CommandConfigurationException(
          "The command object cannot be null.");
    }
    this.command = command;
  }

  @Override
  public void execute(Object... elist) {
    this.command.execute(elist);
  }
}
