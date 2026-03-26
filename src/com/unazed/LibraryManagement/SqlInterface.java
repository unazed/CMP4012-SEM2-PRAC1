package com.unazed.LibraryManagement;

import java.sql.*;
import java.util.List;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;

import com.unazed.LibraryManagement.model.User;

public class SqlInterface
{
  private static final Logger logger = Logger.getLogger(
    SqlInterface.class.getName());
  private static SqlInterface INSTANCE = null;
  private Connection conn;
  private String sessionToken;

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

  public void setSessionToken(String sessionToken)
  {
    logger.info("Session token set: " + sessionToken);
    this.sessionToken = sessionToken;
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
    try (PreparedStatement stmt = conn.prepareCall(
      "SELECT * FROM library_api.register_user(?, ?, ?)");)
    {
      stmt.setString(1, email);
      stmt.setString(2, username);
      stmt.setString(3, password);
      ResultSet rs = stmt.executeQuery();
      if (!rs.next())
        throw new SQLException("No result returned");
      return SqlApiResult.fromResultSet(rs, User.class);
    } catch (SQLException sqlExc)
    {
      logger.log(Level.SEVERE, "Failed to register user:", sqlExc);
      throw sqlExc;
    }
  }

  public SqlApiResult<User> login(
    String email, String password) throws SQLException
  {
    try (PreparedStatement stmt = conn.prepareCall(
      "SELECT * FROM library_api.login_user(?, ?)");)
    {
      stmt.setString(1, email);
      stmt.setString(2, password);
      ResultSet rs = stmt.executeQuery();
      if (!rs.next())
        throw new SQLException("No result returned");
      return SqlApiResult.fromResultSet(rs, User.class);
    } catch (SQLException sqlExc)
    {
      logger.log(Level.SEVERE, "Failed to log in user:", sqlExc);
      throw sqlExc;
    }
  }

  public SqlApiResult<User> loginWithToken(String token) throws SQLException
  {
    try (PreparedStatement stmt = conn.prepareCall(
      "SELECT * FROM library_api.get_token_information(?)");)
    {
      stmt.setString(1, token);
      ResultSet rs = stmt.executeQuery();
      if (!rs.next())
        throw new SQLException("No result returned");
      return SqlApiResult.fromResultSet(rs, User.class);
    } catch (SQLException sqlExc)
    {
      logger.log(Level.SEVERE, "Failed to log in with token:", sqlExc);
      throw sqlExc;
    }
  }

  public SqlApiResult<List<User>> getMembers() throws SQLException
  {
    if (sessionToken == null)
      throw new IllegalStateException("Session token not set");
    try (PreparedStatement stmt = conn.prepareCall(
      "SELECT * FROM library_api.get_members(?)");)
    {
      stmt.setString(1, sessionToken);
      ResultSet rs = stmt.executeQuery();
      if (!rs.next())
        throw new SQLException("No result returned");
      return SqlApiResult.fromResultSetList(rs, User.class);
    } catch (SQLException sqlExc)
    {
      logger.log(Level.SEVERE, "Failed to get members:", sqlExc);
      throw sqlExc;
    }
  }
}
