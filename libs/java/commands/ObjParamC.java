package commands;

/**
 * This class represents the basic shell of a command object that acts on
 * another object given at runtime.
 *
 * Use the inherited methods getObject() and setObject() to get and set the
 * object the command object acts on.
 *
 * @author aliu
 *
 * @param <E> The type of the object that this command should act on.
 */
public abstract class ObjParamC<E> extends ParamC {

  private E object;

  public ObjParamC(E object, String... strings) {
    super(strings);
    if (object == null)
      throw new CommandConfigurationException(
          "The object this command acts on cannot be null");
    this.object = object;
  }

  protected E getObject() { return object; }

  protected void setObject(E object) {
    if (object == null)
      throw new CommandConfigurationException(
          "The object this command acts on cannot be null");
    this.object = object;
  }
}
