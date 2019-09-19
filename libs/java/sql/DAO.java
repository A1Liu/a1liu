package sql;

import static sql.DAOUtil.prepareStatement;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/**
 *
 * Basic methods associated with a Database Access Object (DAO)
 *
 * @author aliu
 *
 */
public abstract class DAO {

  DAOFactory daoFactory;

  public DAO(DAOFactory daoFactory) { this.daoFactory = daoFactory; }

  /**
   * execute sql statement that doesn't return anything
   * @param sql the statement to execute
   * @param errorStatement statement to put in the DAO exception error statement
   * @param values values to add to the prepared statement
   * @throws DAOException if something goes wrong at the database level
   */
  public void executeVoid(String sql, String errorStatement, Object... values)
      throws DAOException {
    try (Connection connection = daoFactory.getConnection();
         PreparedStatement statement =
             prepareStatement(connection, sql, false, values);

    ) {
      int affectedRows = statement.executeUpdate();
      if (affectedRows == 0) {
        throw new DAOException(errorStatement);
      }
    } catch (SQLException e) {
      throw new DAOException(e);
    }
  }

  /**
   * executes an SQL statement and returns whether the statement returned any
   * results
   * @param sql the sql statement to execute
   * @param values the values to add to the prepared statement
   * @return the appropriate boolean for the sql statement
   * @throws DAOException if something is wrong at the database level
   */
  public boolean executeBoolean(String sql, Object... values)
      throws DAOException {

    boolean bool = false;

    try (Connection connection = daoFactory.getConnection();
         PreparedStatement statement =
             prepareStatement(connection, sql, false, values);
         ResultSet resultSet = statement.executeQuery();) {
      bool = resultSet.next();
    } catch (SQLException e) {
      throw new DAOException(e);
    }
    return bool;
  }
}
