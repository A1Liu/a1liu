package sql;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Statement;

/**
 *
 * Utility methods for DAO's
 *
 * @author BalusC, Albert Liu
 * @link http://balusc.blogspot.com/2008/07/dao-tutorial-data-layer.html
 *
 */
public class DAOUtil {
  private DAOUtil() {}

  /**
   * Returns a PreparedStatement of the given connection, set with the given SQL
   * query and the given parameter values.
   * @param connection The Connection to create the PreparedStatement from.
   * @param sql The SQL query to construct the PreparedStatement with.
   * @param returnGeneratedKeys Set whether to return generated keys or not.
   * @param values The parameter values to be set in the created
   *     PreparedStatement.
   * @throws SQLException If something fails during creating the
   *     PreparedStatement.
   */
  public static PreparedStatement
  prepareStatement(Connection connection, String sql,
                   boolean returnGeneratedKeys, Object... values)
      throws SQLException {
    PreparedStatement statement = connection.prepareStatement(
        sql, returnGeneratedKeys ? Statement.RETURN_GENERATED_KEYS
                                 : Statement.NO_GENERATED_KEYS);
    setValues(statement, values);
    return statement;
  }

  /**
   * Set the given parameter values in the given PreparedStatement.
   * @param connection The PreparedStatement to set the given parameter values
   *     in.
   * @param values The parameter values to be set in the created
   *     PreparedStatement.
   * @throws SQLException If something fails during setting the
   *     PreparedStatement values.
   */
  public static void setValues(PreparedStatement statement, Object... values)
      throws SQLException {
    for (int i = 0; i < values.length; i++) {
      statement.setObject(i + 1, values[i]);
    }
  }

  /**
   * Converts the given java.util.Date to java.sql.Date.
   * @param date The java.util.Date to be converted to java.sql.Date.
   * @return The converted java.sql.Date.
   */
  public static Date toSqlDate(java.util.Date date) {
    return (date != null) ? new Date(date.getTime()) : null;
  }

  /**
   * Builds a SELECT query from given parameters. Uses format <br>
   * <code>
   * SELECT &lt;columns&gt; FROM &lt;table&gt; WHERE &lt;conditions&gt;
   * </code>
   * @param columns the columns to select
   * @param table the table to query from
   * @param conditions the conditions to query the table by
   * @return a formatted query
   */
  public static String buildSelect(String columns, String table,
                                   String conditions) {
    return "SELECT " + columns + " FROM " + table + " WHERE " + conditions;
  }

  /**
   * Builds a SELECT query from given parameters. Uses format <br>
   * <code>
   * SELECT &lt;columns&gt; FROM &lt;table&gt; WHERE &lt;conditions&gt;
   * &lt;additional&gt;
   * </code>
   * @param columns the columns to select
   * @param table the table to query from
   * @param conditions the conditions to query the table by
   * @param additional additional arguments to add to the query
   * @return a formatted query
   */
  public static String buildSelect(String columns, String table,
                                   String conditions, String additional) {
    return buildSelect(columns, table, conditions) + " " + additional;
  }
}
