package com.unazed.LibraryManagement;

import java.sql.*;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;

public final class SqlInterface
{
  private static final Logger logger = Logger.getLogger(
    SqlInterface.class.getName());
  private Connection conn;

  public SqlInterface(String url)
    throws SQLException
  {
    try
    {
      this.conn = DriverManager.getConnection(url);
      logger.info("Connected to SQL server: " + url);
    } catch (SQLException sqlExc)
    {
      logger.log(Level.SEVERE,
        "Failed to connect to SQL server: " + sqlExc.getMessage());
      throw sqlExc;
    }
  }

  public SqlInterface(String url, Properties props)
    throws SQLException
  {
    try
    {
      conn = DriverManager.getConnection(url, props);
      logger.info("Connected to SQL server (w/ props): " + url);
    } catch (SQLException sqlExc)
    {
      logger.log(Level.SEVERE,
	      "Failed to connect to SQL server: " + sqlExc.getMessage());
      throw sqlExc;
    }
  }

  /* call library_api.register(email, username, password) */
  public void register(String email, String username, String password)
    throws SQLException
  {
    try (CallableStatement stmt = conn.prepareCall(
      "{call library_api.register(?, ?, ?)}"))
    {
      stmt.setString(1, email);
      stmt.setString(2, username);
      stmt.setString(3, password);
      stmt.execute();
    } catch (SQLException sqlExc)
    {
      logger.log(Level.SEVERE,
        "Failed to register user: " + sqlExc.getMessage());
      throw sqlExc;
    }
  }
}
