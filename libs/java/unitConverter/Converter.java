package unitConverter;

/**
 * Converts units to other units
 * @author aliu
 *
 */
public class Converter {

  private Converter() {}

  /**
   *
   * @param fromAmount
   * @param from
   * @param to
   * @return
   */
  public double convertValue(double fromAmount, Unit from, Unit to) {
    if (from.getUnitType() != to.getUnitType())
      throw new IllegalArgumentException("Units arent the same!");
    return fromAmount * from.getConversion() / to.getConversion();
  }
}
