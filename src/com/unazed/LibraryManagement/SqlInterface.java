package com.unazed.LibraryManagement;

import java.sql.*;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;

public class SqlInterface
{
  private static final Logger logger = Logger.getLogger(
    SqlInterface.class.getName());
  private static SqlInterface INSTANCE = null;
  private Connection conn;

  private SqlInterface(String url)
    throws SQLException
  {
    try
    {
      conn = DriverManager.getConnection(url);
      logger.info("Connected to SQL server: " + url);
    } catch (SQLException sqlExc)
    {
      logger.log(Level.SEVERE, "Failed to connect to SQL server:", sqlExc);
      throw sqlExc;
    }
  }

  public static SqlInterface newInstance(String url) throws SQLException
  {
    if (INSTANCE != null)
      throw new IllegalStateException("SqlInterface instance already exists");
    INSTANCE = new SqlInterface(url);
    return INSTANCE;
  }

  public static SqlInterface get()
  {
    if (INSTANCE == null)
      throw new IllegalStateException("SqlInterface instance not initialized");
    return INSTANCE;
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
      logger.log(Level.SEVERE, "Failed to connect to SQL server:", sqlExc);
      throw sqlExc;
    }
  }

  public Connection getConnection()
  {
    return conn;
  }
}
