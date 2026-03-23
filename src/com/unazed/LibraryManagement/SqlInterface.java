package com.unazed.LibraryManagement;

import java.sql.*;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;

import com.unazed.LibraryManagement.model.User;

public class SqlInterface
{
  private static final Logger logger = Logger.getLogger(
    SqlInterface.class.getName());
  private static SqlInterface instance;
  private Connection conn;

  private SqlInterface(String url)
    throws SQLException
  {
    try
    {
      this.conn = DriverManager.getConnection(url);
      logger.info("Connected to SQL server: " + url);
    } catch (SQLException sqlExc)
    {
      logger.log(Level.SEVERE, "Failed to connect to SQL server:", sqlExc);
      throw sqlExc;
    }
  }

  public static SqlInterface newInstance(String url) throws SQLException
  {
    if (instance != null)
      throw new IllegalStateException("SqlInterface instance already exists");
    return new SqlInterface(url);
  }

  public static SqlInterface get()
  {
    if (instance == null)
      throw new IllegalStateException("SqlInterface instance not initialized");
    return instance;
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

  public SqlApiResult<User> register(
    String email, String username, String password) throws SQLException
  {
    CallableStatement stmt;
    try
    {
      stmt = conn.prepareCall("{call library_api.register(?, ?, ?)}");
      stmt.setString(1, email);
      stmt.setString(2, username);
      stmt.setString(3, password);
      stmt.execute();
    } catch (SQLException sqlExc)
    {
      logger.log(Level.SEVERE, "Failed to register user:", sqlExc);
      throw sqlExc;
    }

    boolean success = stmt.getBoolean("success");
    String errorCode = stmt.getString("error_code");
    if (!success)
      return new SqlApiResult<>(false, errorCode, null);
    
    return new SqlApiResult<>(
      true, null, User.fromJson(stmt.getString("data")));
  }

  public SqlApiResult<User> login(
    String email, String password) throws SQLException
  {
    CallableStatement stmt;
    try
    {
      stmt = conn.prepareCall("{call library_api.login(?, ?)}");
      stmt.setString(1, email);
      stmt.setString(2, password);
      stmt.execute();
    } catch (SQLException sqlExc)
    {
      logger.log(Level.SEVERE, "Failed to log in user:", sqlExc);
      throw sqlExc;
    }

    boolean success = stmt.getBoolean("success");
    String errorCode = stmt.getString("error_code");
    if (!success)
      return new SqlApiResult<>(false, errorCode, null);
    
    return new SqlApiResult<>(
      true, null, User.fromJson(stmt.getString("data")));
  }
}
