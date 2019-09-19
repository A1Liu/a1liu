package sql;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.sql.DataSource;

/**
 *
 * Creates DAO instances
 *
 * @authors BalusC, Albert Liu
 * @link http://balusc.blogspot.com/2008/07/dao-tutorial-data-layer.html
 *
 */
public abstract class DAOFactory {
  /*
database is javabase.jdbc

url part 1: jdbc:mysql://
  driver to use

url part 2: localhost:3306/
  ip to look for

url part 3: javabase
  database at ip

url part 4: ?verifyServerCertificate=false&useSSL=true
  decisions about using certificates and SSL

javabase.jdbc.url =
jdbc:mysql://localhost:3306/javabase?verifyServerCertificate=false&useSSL=true
javabase.jdbc.driver = com.mysql.jdbc.Driver
javabase.jdbc.username = java
javabase.jdbc.password = java
   */

  /**
   * <pre>
   * Returns a new DAOFactory instance for the given database name. Example
   *usage:
   *
   * <code>
   * String url =
   *"jdbc:mysql://localhost:3306/javabase?verifyServerCertificate=false&useSSL=true";
   * String driverName = "com.mysql.jdbc.Driver";
   * String username = "username";
   * String password = "password";
   * DAOFactory daoFactory = DAOFactory.getInstance(url,driverName, username,
   *password);
   *</code></pre>
   * @param url url to load from
   * @param driverClassName class name of the driver
   * @param username username to access database
   * @param password password to access database
   * @return A new DAOFactory instance at the given url, with the given driver
   *class
   * @throws DAOConfigurationException If either the driver cannot be loaded or
   *the datasource cannot be found.
   */
  public static DAOFactory getInstance(String url, String driverClassName)
      throws DAOConfigurationException {
    return getInstance(url, driverClassName, null, null);
  }

  /**
   * <p>
   * Returns a new DAOFactory instance for the given database name. Example
   *usage:
   * </p>
   * <code>
   * String url =
   *"jdbc:mysql://localhost:3306/javabase?verifyServerCertificate=false&useSSL=true";
   * String driverName = "com.mysql.jdbc.Driver";
   * String username = "username";
   * String password = "password";
   * DAOFactory daoFactory = DAOFactory.getInstance(url,driverName, username,
   *password);
   *</code>
   * @param url url to load from
   * @param driverClassName class name of the driver (Optional)
   * @param username username to access database (Optional)
   * @param password password to access database (Optional)
   * @return A new DAOFactory instance at the given url, with the given driver
   *class (if specified)
   * @throws DAOConfigurationException If either the driver cannot be loaded or
   *the datasource cannot be found.
   */
  public static DAOFactory getInstance(String url, String driverClassName,
                                       String username, String password)
      throws DAOConfigurationException {
    //		if (databaseName == null) {
    //		    throw new DAOConfigurationException("Database name is
    //null.");
    //		}
    //		DAOProperties properties = new DAOProperties(name);
    //		String url = properties.getProperty(PROPERTY_URL, true);
    //		String driverClassName = properties.getProperty(PROPERTY_DRIVER,
    //false); 		String password = properties.getProperty(PROPERTY_PASSWORD,
    //false); 		String username = properties.getProperty(PROPERTY_USERNAME,
    //password != null);
    DAOFactory instance;

    // If driver is specified, then load it to let it register itself with
    // DriverManager.
    if (driverClassName != null) {
      try {
        Class.forName(driverClassName);
      } catch (ClassNotFoundException e) {
        throw new DAOConfigurationException("Driver class '" + driverClassName +
                                                "' is missing in classpath.",
                                            e);
      }
      instance = new DriverManagerDAOFactory(url, username, password);
    }

    // Else assume URL as DataSource URL and lookup it in the JNDI.
    else {
      DataSource dataSource;
      try {
        dataSource = (DataSource) new InitialContext().lookup(url);
      } catch (NamingException e) {
        throw new DAOConfigurationException(
            "DataSource '" + url + "' is missing in JNDI.", e);
      }
      if (username != null) {
        instance =
            new DataSourceWithLoginDAOFactory(dataSource, username, password);
      } else {
        instance = new DataSourceDAOFactory(dataSource);
      }
    }

    return instance;
  }

  /**
   * Returns a connection to the database. Package private so that it can be
   * used inside the DAO package only.
   * @return A connection to the database.
   * @throws SQLException If acquiring the connection fails.
   */
  public abstract Connection getConnection() throws SQLException;
}

/**
 * The DriverManager based DAOFactory.
 */
class DriverManagerDAOFactory extends DAOFactory {
  private String url;
  private String username;
  private String password;

  DriverManagerDAOFactory(String url, String username, String password) {
    this.url = url;
    this.username = username;
    this.password = password;
  }

  @Override
  public Connection getConnection() throws SQLException {
    return DriverManager.getConnection(url, username, password);
  }
}

/**
 * The DataSource based SQL DAOFactory.
 */
class DataSourceDAOFactory extends DAOFactory {
  private DataSource dataSource;

  DataSourceDAOFactory(DataSource dataSource) { this.dataSource = dataSource; }

  @Override
  public Connection getConnection() throws SQLException {
    return dataSource.getConnection();
  }
}

/**
 * The DataSource-with-Login based SQL DAOFactory.
 */
class DataSourceWithLoginDAOFactory extends DAOFactory {
  private DataSource dataSource;
  private String username;
  private String password;

  DataSourceWithLoginDAOFactory(DataSource dataSource, String username,
                                String password) {
    this.dataSource = dataSource;
    this.username = username;
    this.password = password;
  }

  @Override
  public Connection getConnection() throws SQLException {
    return dataSource.getConnection(username, password);
  }
}
