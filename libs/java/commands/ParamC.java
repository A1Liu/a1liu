package commands;

import java.util.ArrayList;
import java.util.List;

/**
 * This class represents an implementation of the Command interface that parses
 * user input into safely castable objects.
 *
 * TODO change the constructors to accept Class<?> as an argument type instead
 * of strings.
 *
 * @author Alyer
 *
 */
public abstract class ParamC implements Command {

  private Object output;

  /**
   * These are the names of the classes of the parameter requirements that this
   * command object takes.
   */
  private final String[] PARAM_REQS;

  /**
   * Constructor with a field allowing for some pre-screening of variable types.
   * The screening doesn't care if user enters extra parameters.
   * @param reqs list of data-types that params should be, in order of
   *     user-entry
   */
  protected ParamC(String... reqs) {
    PARAM_REQS = reqs;
    output = null;
  }

  /**
   * Error traps for all user params that should be java primitives. Ignores any
   * extra parameters
   * @param plist list of parameters that the user has inputted
   */
  public final Object execute(String... plist) {
    if (checkParams(plist)) { // Check if parameters in plist work for the
                              // PARAM_REQS that this command object requires
      List<Object> olist = new ArrayList<Object>();
      int x;
      for (x = 0; x < PARAM_REQS.length; x++) {
        olist.add(paramConvert(PARAM_REQS[x], plist[x]));
      }
      for (int y = x; y < plist.length; y++) {
        olist.add(plist[y]);
      }
      execute(olist.toArray());
    } else {
      throw new CommandException(
          "User input does not match required parameters for this command.");
    }
    Object output = this.output;
    this.output = null;
    return output;
  }

  /**
   * The method this command object should execute. The parameters are objects.
   * If the user input isn't one of String, long, float, double, boolean, or
   * int, then this method has to manually parse from string form.
   * @param elist
   */
  public abstract void execute(Object... elist);

  public final boolean checkParams(Object... input) {
    if (PARAM_REQS.length > input.length)
      return false;
    for (int x = 0; x < PARAM_REQS.length; x++) {
      if (!paramCheck(PARAM_REQS[x], input[x])) {
        return false;
      }
    }
    return true;
  }

  /**
   * Checks the parameters that the user has inputted to see if they fit
   * requirements of PARAM_REQS
   * @param strings the parameters the user inputted
   * @return
   */
  private final boolean checkParams(String... strings) {
    if (PARAM_REQS.length > strings.length)
      return false;
    for (int x = 0; x < PARAM_REQS.length; x++) {
      if (!paramCheck(PARAM_REQS[x], strings[x])) {
        return false;
      }
    }
    return true;
  }

  /**
   * converts a parameter into an object. Only supports the primitives' object
   * forms -- commands that take separate objects need to parse those separately
   * @param paramReq Requirement for the parameter
   * @param param parameter
   * @return Object form of parameter if paramReq is a java primitive type
   */
  private static final Object paramConvert(String paramReq, String param) {
    switch (paramReq.toLowerCase()) {
    case "double":
      return (Double)Double.parseDouble(param);
    case "integer":
    case "int":
      return (Integer)Integer.parseInt(param);
    case "boolean":
      return (Boolean)param.toLowerCase().equals("true");
    case "float":
      return (Float)Float.parseFloat(param);
    case "long":
      return (Long)Long.parseLong(param);
    default:
      return param;
    }
  }

  /**
   * checks whether the parameter is a form of the class specified in paramReq.
   * Only supports java's built in primitive types and strings
   * @param paramReq
   * @param param
   * @return
   */
  private static final boolean paramCheck(String paramReq, Object param) {
    Class<?> paramClass = param.getClass();
    switch (paramReq.toLowerCase()) {
    case "double":
      return paramClass.equals(Double.class);
      // try {o = (Double) param;return true;} catch (Exception e) {return
      // false;}
    case "integer":
    case "int":
      return paramClass.equals(Integer.class);
      // try {o =(Integer) (param);return true;} catch (Exception e) {return
      // false;}
    case "boolean":
      return paramClass.equals(Boolean.class);
      // try {o =(Boolean) (param);return true;} catch (Exception e) {return
      // false;}
    case "float":
      return paramClass.equals(Float.class);
      // try {o =(Float) (param);return true;} catch (Exception e) {return
      // false;}
    case "long":
      return paramClass.equals(Long.class);
      // try {o =(Long) (param);return true;} catch (Exception e) {return
      // false;}
    default:
      return true;
    }
  }

  /**
   * checks whether the parameter is a form of the class specified in paramReq.
   * Only supports java's built in primitive types and strings
   * @param paramReq
   * @param param
   * @return
   */
  private static final boolean paramCheck(String paramReq, String param) {
    switch (paramReq.toLowerCase()) {
    case "double":
      try {
        Double.parseDouble(param);
        return true;
      } catch (NumberFormatException e) {
        return false;
      }
    case "integer":
    case "int":
      try {
        Integer.parseInt(param);
        return true;
      } catch (NumberFormatException e) {
        return false;
      }
    case "boolean":
      return param.toLowerCase().equals("true") ||
          param.toLowerCase().equals("false");
    case "float":
      try {
        Float.parseFloat(param);
        return true;
      } catch (NumberFormatException e) {
        return false;
      }
    case "long":
      try {
        Long.parseLong(param);
        return true;
      } catch (NumberFormatException e) {
        return false;
      }
    default:
      return true;
    }
  }

  protected void setOutput(Object output) { this.output = output; }

  public Object getOutput() { return output; }
}
