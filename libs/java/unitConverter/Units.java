package unitConverter;

import static unitConverter.Unit.*;

/**
 * Constants
 * @author aliu
 *
 */
public final class Units { // TODO Finish the units class

  private Units() {}

  /* -------- Standard -------*/

  /**
   * Unit for money, standard is US dollars
   */
  public static final Unit STANDARD_NA = new StandardUnit(MONEY);

  /**
   * Standard unit for length, standard is metric centimeters
   */
  public static final Unit STANDARD_LENGTH = new StandardUnit(LENGTH);

  /**
   * Standard unit for area, standard is metric centimeters squared
   */
  public static final Unit STANDARD_AREA = new StandardUnit(AREA);

  /**
   * Standard unit for volume, standard is metric centimeters cubed
   */
  public static final Unit STANDARD_VOLUME = new StandardUnit(VOLUME);

  /**
   * Standard unit for mass, standard is metric grams
   */
  public static final Unit STANDARD_MASS = new StandardUnit(MASS);

  /* -------- Money -------*/

  /**
   * Unit for dollars
   */
  public static final Unit DOLLAR = STANDARD_LENGTH;

  public static class Length {
    private Length() {}

    /**
     * Unit for centimeters
     */
    public static final Unit CENTIMETER = new Unit(LENGTH, .01);

    /**
     * Unit for millimeters
     */
    public static final Unit MILLIMETER = new Unit(LENGTH, .001);

    /**
     * Unit for meters
     */
    public static final Unit METER = STANDARD_LENGTH;

    /**
     * Unit for kilometers
     */
    public static final Unit KILOMETER = new Unit(LENGTH, 1000);

    /**
     * Unit for inches
     */
    public static final Unit INCH = new Unit(LENGTH, .00254);

    /**
     * Unit for feet
     */
    public static final Unit FOOT = new Unit(LENGTH, .03048);

    /**
     * Unit for yards
     */
    public static final Unit YARD = new Unit(LENGTH, .09144);

    /**
     * Unit for miles
     */
    public static final Unit MILE = new Unit(LENGTH, 160.9344);
  }

  public static class Area {
    private Area() {}

    /**
     * Unit for centimeters squared
     */
    public static final Unit CENTIMETER_SQUARED = new Unit(AREA, .0001);

    /**
     * Unit for meters squared
     */
    public static final Unit METERS_SQUARED = STANDARD_AREA;

    /**
     * Unit for hectare
     */
    public static final Unit HECTARE = new Unit(AREA, 10000);

    /**
     * Unit for kilometers squared
     */
    public static final Unit KILOMETERS_SQUARED = new Unit(AREA, 1000000);

    /**
     * Unit for inches squared
     */
    public static final Unit INCHES_SQUARED = new Unit(AREA, .00064516);

    /**
     * Unit for feet squared
     */
    public static final Unit FEET_SQUARED = new Unit(AREA, .09290304);

    /**
     * Unit for yards squared
     */
    public static final Unit YARDS_SQUARED = new Unit(AREA, 0.83612736);

    /**
     * Unit for miles squared
     */
    public static final Unit MILES_SQUARED = new Unit(AREA, 2589988.110336);

    /**
     * Unit for acres squared
     */
    public static final Unit ACRES = new Unit(AREA, 4046.8564224);
  }

  public static class Volume {
    private Volume() {}

    /**
     * Unit for centimeters cubed
     */
    public static final Unit CENTIMETER_CUBED = STANDARD_VOLUME;

    /**
     * Unit for milliliter
     */
    public static final Unit MILLILITER = STANDARD_VOLUME;

    /**
     * Unit for liter
     */
    public static final Unit LITER = new Unit(VOLUME, 1000);
  }

  public static class Mass {
    private Mass() {}

    /**
     * Unit for grams
     */
    public static final Unit GRAM = STANDARD_MASS;

    /**
     * Unit for kilograms
     */
    public static final Unit KILOGRAM = new Unit(MASS, 1000);
  }

  public static class Misc {
    private Misc() {}

    /**
     * Unit for a 'pinch'
     */
    public static final Unit PINCH_MASS = new Unit(MASS, .1);
  }
}
