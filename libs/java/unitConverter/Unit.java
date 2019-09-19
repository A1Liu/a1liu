package unitConverter;

/**
 * Object that represents a unit of measure.
 * <p>
 * <b>Standards:</b><br>
 * Money: US Dollars<br>
 * Length: meters<br>
 * Area: meters^2<br>
 * Volume: meters^3<br>
 * Mass: grams
 * </p>
 *
 * @author aliu
 *
 */
class Unit {

  static final int MONEY = 0;
  static final int LENGTH = 1;
  static final int AREA = 2;
  static final int VOLUME = 3;
  static final int MASS = 4;

  private final int unitType;
  private final double conversion;

  Unit(int unitType, double conversion) {
    this.unitType = unitType;
    this.conversion = conversion;
  }

  /**
   * Returns the unit type of this unit, i.e. length, area, volume, etc
   * @return the unit type of this unit
   */
  int getUnitType() { return unitType; }

  /**
   * Returns the amount of standard units this unit is equivalent to
   * @return the amount of standard units this unit is equivalent to
   */
  double getConversion() { return conversion; }
}

/**
 * Object that represents a standard unit of measure
 * @author aliu
 *
 */
final class StandardUnit extends Unit {
  StandardUnit(int unitType) { super(unitType, 1); }
}

/*
 * Standards:
 * 0 - Money, USD
 * 1 - Length, centimeters
 * 2 - Area, centimeters^2
 * 3 - Volume, centimeters^3
 * 4 - Mass, grams
 *
 *
 *
 *
 *
 *
 */
